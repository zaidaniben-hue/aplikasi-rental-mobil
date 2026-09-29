// Supabase Edge Function: checkin-settlement
// Handles Check-In Return, Overtime Penalty Calculation (60m grace, >5h = 1 full day),
// Fuel Shortfall fee, Damage Surcharges, Deposit Settlement, and resets vehicle to TERSEDIA.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface CheckinPayload {
  rentalId: string;
  odometerEnd: number;
  fuelLevelEnd: number; // 1 to 8
  actualEndTime?: string; // ISO 8601, defaults to now
  bodyDefectsEnd?: Array<{
    id: string;
    view: "front" | "back" | "left" | "right";
    x: number;
    y: number;
    type: "scratch" | "dent" | "broken";
    severity: "low" | "medium" | "high";
    notes?: string;
  }>;
  damageFeeManual?: number;
  fuelCostPerBar?: number; // Default Rp 35,000 per 1/8 bar
  inspectorId?: string;
  notes?: string;
  photoUrls?: string[];
  vehicleNeedsMaintenance?: boolean;
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

    const body: CheckinPayload = await req.json();
    const {
      rentalId,
      odometerEnd,
      fuelLevelEnd,
      actualEndTime = new Date().toISOString(),
      bodyDefectsEnd = [],
      damageFeeManual = 0,
      fuelCostPerBar = 35000,
      inspectorId,
      notes,
      photoUrls = [],
      vehicleNeedsMaintenance = false,
    } = body;

    if (!rentalId || odometerEnd === undefined || !fuelLevelEnd) {
      return new Response(
        JSON.stringify({ error: "Missing required parameters (rentalId, odometerEnd, fuelLevelEnd)" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 1. Fetch Rental & Check-out inspection
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

    if (rental.rental_status !== "ACTIVE") {
      return new Response(
        JSON.stringify({ error: `Pengembalian hanya dapat diproses untuk sewa berstatus AKTIF (Status saat ini: ${rental.rental_status})` }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Fetch initial inspection to compare
    const { data: checkoutInsp, error: inspFetchErr } = await supabaseClient
      .from("inspections")
      .select("*")
      .eq("rental_id", rentalId)
      .eq("type", "CHECK_OUT")
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    const startOdo = checkoutInsp?.odometer ?? rental.vehicle.odometer_current;
    if (odometerEnd < startOdo) {
      return new Response(
        JSON.stringify({ 
          error: `Odometer akhir (${odometerEnd} km) tidak boleh lebih kecil dari odometer awal (${startOdo} km)` 
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Kalkulasi Overtime (Keterlambatan)
    // Aturan PRD: Toleransi grace period: 60 menit. Keterlambatan > 5 jam dihitung tarif 1 hari penuh.
    const plannedEnd = new Date(rental.planned_end_time);
    const actualEnd = new Date(actualEndTime);
    const dailyRate = Number(rental.daily_rate);

    let overtimeHours = 0;
    let overtimeFee = 0;

    const diffMillis = actualEnd.getTime() - plannedEnd.getTime();
    const diffMinutes = diffMillis / (1000 * 60);

    const GRACE_PERIOD_MINUTES = 60;

    if (diffMinutes > GRACE_PERIOD_MINUTES) {
      // Exceeded grace period, calculate billable hours
      overtimeHours = Math.ceil((diffMinutes - GRACE_PERIOD_MINUTES) / 60);

      if (overtimeHours > 5) {
        // Denda > 5 jam: dihitung tarif 1 hari penuh
        overtimeFee = dailyRate;
      } else {
        // Tarif per jam keterlambatan (standar: 10% dari tarif harian per jam)
        const hourlyRate = dailyRate * 0.10;
        overtimeFee = overtimeHours * hourlyRate;
      }
    }

    // 3. Kalkulasi Penggantian Bahan Bakar
    const startFuel = checkoutInsp?.fuel_level ?? 8;
    let fuelFee = 0;
    const fuelDiff = startFuel - fuelLevelEnd;
    if (fuelDiff > 0) {
      fuelFee = fuelDiff * fuelCostPerBar;
    }

    // 4. Biaya Kerusakan Bodi
    const damageFee = Math.max(0, Number(damageFeeManual));

    // 5. Kalkulasi Total & Settlement Deposit
    const baseAmount = Number(rental.base_amount);
    const totalAmount = baseAmount + overtimeFee + fuelFee + damageFee;
    const downPayment = Number(rental.down_payment || 0);
    const depositAmount = Number(rental.deposit_amount || 0);

    // Total sudah dibayar penyewa di muka
    const totalPrepaid = downPayment + depositAmount;

    // Sisa yang harus ditagih ke pelanggan atau dikembalikan
    // Net = Total Tagihan - Pembayaran di Muka
    let netDue = totalAmount - totalPrepaid;
    let refundDeposit = 0;

    if (netDue < 0) {
      // Ada sisa deposit yang harus dikembalikan ke penyewa
      refundDeposit = Math.abs(netDue);
      netDue = 0;
    }

    // 6. Catat Inspeksi CHECK_IN
    const { data: returnInspection, error: returnInspErr } = await supabaseClient
      .from("inspections")
      .insert({
        rental_id: rentalId,
        vehicle_id: rental.vehicle_id,
        type: "CHECK_IN",
        odometer: odometerEnd,
        fuel_level: fuelLevelEnd,
        body_defects: bodyDefectsEnd,
        notes: notes || "Pemeriksaan serah terima pengembalian (Check-In)",
        inspector_id: inspectorId,
        photo_urls: photoUrls,
      })
      .select()
      .single();

    if (returnInspErr) {
      return new Response(
        JSON.stringify({ error: "Gagal menyimpan inspeksi pengembalian: " + returnInspErr.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 7. Update Transaksi Sewa
    const { data: updatedRental, error: updateRentalErr } = await supabaseClient
      .from("rentals")
      .update({
        actual_end_time: actualEndTime,
        overtime_hours: overtimeHours,
        overtime_fee: overtimeFee,
        fuel_fee: fuelFee,
        damage_fee: damageFee,
        total_amount: totalAmount,
        refund_deposit: refundDeposit,
        rental_status: "COMPLETED",
        payment_status: netDue === 0 ? "PAID" : "SETTLEMENT_REQUIRED",
        updated_at: new Date().toISOString(),
      })
      .eq("id", rentalId)
      .select()
      .single();

    if (updateRentalErr) {
      return new Response(
        JSON.stringify({ error: "Gagal memperbarui transaksi sewa: " + updateRentalErr.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 8. Update Status Kendaraan
    // Jika ada kerusakan berat atau flag needs maintenance, set PERAWATAN. Lainnya kembali TERSEDIA.
    const newVehicleStatus = vehicleNeedsMaintenance || damageFee > 500000 ? "PERAWATAN" : "TERSEDIA";
    await supabaseClient
      .from("vehicles")
      .update({
        status: newVehicleStatus,
        odometer_current: odometerEnd,
        updated_at: new Date().toISOString(),
      })
      .eq("id", rental.vehicle_id);

    return new Response(
      JSON.stringify({
        success: true,
        message: "Pengembalian berhasil diproses dan invoice tagihan telah dikalkulasi.",
        settlement: {
          transactionCode: rental.transaction_code,
          durationDays: rental.duration_days,
          baseAmount,
          overtimeHours,
          overtimeFee,
          fuelShortfallBars: Math.max(0, fuelDiff),
          fuelFee,
          damageFee,
          totalAmount,
          downPayment,
          depositAmount,
          refundDeposit,
          netDueFromCustomer: netDue,
          newVehicleStatus,
        },
        rental: updatedRental,
        inspection: returnInspection,
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
