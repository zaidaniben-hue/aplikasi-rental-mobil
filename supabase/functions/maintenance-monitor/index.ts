// Supabase Edge Function: maintenance-monitor
// Evaluates fleet maintenance thresholds (Green, Yellow, Red)
// Can be called manually by Flutter or invoked by pg_cron periodic schedule

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // 1. Fetch all active vehicles and their rules
    const { data: vehicles, error: vehErr } = await supabaseClient
      .from("vehicles")
      .select("id, plate_number, brand, model, odometer_current, status, is_active")
      .eq("is_active", true);

    if (vehErr) {
      return new Response(
        JSON.stringify({ error: "Gagal mengambil data armada: " + vehErr.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const report: Array<{
      vehicleId: string;
      plateNumber: string;
      brand: string;
      model: string;
      currentOdometer: number;
      overallHealth: "HIJAU" | "KUNING" | "MERAH";
      alerts: Array<{
        serviceType: string;
        status: "HIJAU" | "KUNING" | "MERAH";
        kmRemaining: number | null;
        daysRemaining: number | null;
      }>;
      actionTaken?: string;
    }> = [];

    const now = new Date();

    for (const vehicle of (vehicles || [])) {
      const { data: rules } = await supabaseClient
        .from("maintenance_rules")
        .select("*")
        .eq("vehicle_id", vehicle.id);

      let overallHealth: "HIJAU" | "KUNING" | "MERAH" = "HIJAU";
      const alerts: Array<{
        serviceType: string;
        status: "HIJAU" | "KUNING" | "MERAH";
        kmRemaining: number | null;
        daysRemaining: number | null;
      }> = [];

      for (const rule of (rules || [])) {
        let kmRemaining: number | null = null;
        let daysRemaining: number | null = null;

        if (rule.interval_km) {
          const nextDueKm = Number(rule.last_service_km) + Number(rule.interval_km);
          kmRemaining = nextDueKm - Number(vehicle.odometer_current);
        }

        if (rule.interval_days) {
          const lastDate = new Date(rule.last_service_date);
          const nextDueDate = new Date(lastDate.getTime() + rule.interval_days * 24 * 60 * 60 * 1000);
          daysRemaining = Math.ceil((nextDueDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
        }

        // Check Red (Jatuh Tempo)
        const isKmOverdue = kmRemaining !== null && kmRemaining <= 0;
        const isDateOverdue = daysRemaining !== null && daysRemaining <= 0;

        // Check Yellow (Siaga: <= 500 km or <= 7 days)
        const isKmNear = kmRemaining !== null && kmRemaining <= 500;
        const isDateNear = daysRemaining !== null && daysRemaining <= 7;

        let ruleStatus: "HIJAU" | "KUNING" | "MERAH" = "HIJAU";

        if (isKmOverdue || isDateOverdue) {
          ruleStatus = "MERAH";
          overallHealth = "MERAH";
        } else if (isKmNear || isDateNear) {
          ruleStatus = "KUNING";
          if (overallHealth !== "MERAH") {
            overallHealth = "KUNING";
          }
        }

        if (ruleStatus !== "HIJAU") {
          alerts.push({
            serviceType: rule.service_type,
            status: ruleStatus,
            kmRemaining,
            daysRemaining,
          });
        }
      }

      let actionTaken = "NORMAL";

      // If unit is MERAH and currently TERSEDIA, lock to PERAWATAN to prevent unsafe rental
      if (overallHealth === "MERAH" && vehicle.status === "TERSEDIA") {
        await supabaseClient
          .from("vehicles")
          .update({
            status: "PERAWATAN",
            updated_at: new Date().toISOString(),
          })
          .eq("id", vehicle.id);

        actionTaken = "LOCKED_TO_PERAWATAN";
      }

      report.push({
        vehicleId: vehicle.id,
        plateNumber: vehicle.plate_number,
        brand: vehicle.brand,
        model: vehicle.model,
        currentOdometer: vehicle.odometer_current,
        overallHealth,
        alerts,
        actionTaken,
      });
    }

    const summary = {
      totalVehicles: report.length,
      greenCount: report.filter(r => r.overallHealth === "HIJAU").length,
      yellowCount: report.filter(r => r.overallHealth === "KUNING").length,
      redCount: report.filter(r => r.overallHealth === "MERAH").length,
      lockedCount: report.filter(r => r.actionTaken === "LOCKED_TO_PERAWATAN").length,
    };

    return new Response(
      JSON.stringify({
        success: true,
        summary,
        fleetHealth: report,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    return new Response(
      JSON.stringify({ error: message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
