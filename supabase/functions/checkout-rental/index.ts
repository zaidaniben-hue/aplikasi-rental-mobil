// Supabase Edge Function: checkout-rental
// Handles Check-Out Handover, initial inspection, odometer/fuel logging, and sets vehicle to DISEWA

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface CheckoutPayload {
  rentalId: string;
  odometerStart: number;
  fuelLevel: number; // 1 to 8
  bodyDefects?: Array<{
    id: string;
    view: "front" | "back" | "left" | "right";
    x: number;
    y: number;
    type: "scratch" | "dent" | "broken";
    severity: "low" | "medium" | "high";
    notes?: string;
  }>;
  notes?: string;
  inspectorId?: string;
  photoUrls?: string[];
  depositReceived?: number;
  paymentMethod?: string;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const body: CheckoutPayload = await req.json();
    const { rentalId, odometerStart, fuelLevel, bodyDefects = [], notes, inspectorId, photoUrls = [], depositReceived, paymentMethod } = body;

    if (!rentalId || odometerStart === undefined || !fuelLevel) {
      return new Response(
        JSON.stringify({ error: "Missing required parameters (rentalId, odometerStart, fuelLevel)" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (fuelLevel < 1 || fuelLevel > 8) {
      return new Response(
        JSON.stringify({ error: "Level bahan bakar harus berada pada skala 1/8 hingga 8/8" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 1. Fetch current rental
    const { data: rental, error: fetchErr } = await supabaseClient
      .from("rentals")
      .select("*, vehicle:vehicles(*), customer:customers(*)")
      .eq("id", rentalId)
      .single();

    if (fetchErr || !rental) {
      return new Response(
        JSON.stringify({ error: "Transaksi sewa tidak ditemukan" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (rental.rental_status === "ACTIVE") {
      return new Response(
        JSON.stringify({ error: "Transaksi ini sudah dalam status AKTIF (sudah di-checkout)" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (rental.rental_status === "COMPLETED" || rental.rental_status === "CANCELLED") {
      return new Response(
        JSON.stringify({ error: `Transaksi tidak dapat di-checkout karena status ${rental.rental_status}` }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Insert CHECK_OUT Inspection
    const { data: inspection, error: inspErr } = await supabaseClient
      .from("inspections")
      .insert({
        rental_id: rentalId,
        vehicle_id: rental.vehicle_id,
        type: "CHECK_OUT",
        odometer: odometerStart,
        fuel_level: fuelLevel,
        body_defects: bodyDefects,
        notes: notes || "Pemeriksaan serah terima check-out",
        inspector_id: inspectorId,
        photo_urls: photoUrls,
      })
      .select()
      .single();

    if (inspErr) {
      return new Response(
        JSON.stringify({ error: "Gagal menyimpan formulir inspeksi: " + inspErr.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 3. Update Vehicle state to DISEWA and current odometer
    const { error: vehErr } = await supabaseClient
      .from("vehicles")
      .update({
        status: "DISEWA",
        odometer_current: odometerStart,
        updated_at: new Date().toISOString(),
      })
      .eq("id", rental.vehicle_id);

    if (vehErr) {
      return new Response(
        JSON.stringify({ error: "Gagal memperbarui status kendaraan: " + vehErr.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 4. Update Rental status to ACTIVE
    const rentalUpdate: Record<string, unknown> = {
      rental_status: "ACTIVE",
      start_time: new Date().toISOString(), // Actual checkout time
      updated_at: new Date().toISOString(),
    };

    if (depositReceived !== undefined && depositReceived > 0) {
      rentalUpdate.deposit_amount = depositReceived;
    }
    if (paymentMethod) {
      rentalUpdate.payment_method = paymentMethod;
    }

    const { data: updatedRental, error: rentUpErr } = await supabaseClient
      .from("rentals")
      .update(rentalUpdate)
      .eq("id", rentalId)
      .select()
      .single();

    if (rentUpErr) {
      return new Response(
        JSON.stringify({ error: "Gagal memperbarui status transaksi: " + rentUpErr.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "Serah terima unit (Check-out) berhasil dicatat. Kendaraan kini berstatus DISEWA.",
        rental: updatedRental,
        inspection,
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
