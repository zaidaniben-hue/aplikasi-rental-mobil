// Supabase Edge Function: validate-and-book
// Handles atomic anti double-booking checks and reservation creation

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface BookingPayload {
  customerId: string;
  vehicleId: string;
  startTime: string; // ISO 8601
  plannedEndTime: string; // ISO 8601
  dailyRate: number;
  downPayment?: number;
  depositAmount?: number;
  notes?: string;
  handledBy?: string;
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

    const body: BookingPayload = await req.json();
    const { customerId, vehicleId, startTime, plannedEndTime, dailyRate, downPayment = 0, depositAmount = 0, notes, handledBy } = body;

    if (!customerId || !vehicleId || !startTime || !plannedEndTime || !dailyRate) {
      return new Response(
        JSON.stringify({ error: "Missing required parameters (customerId, vehicleId, startTime, plannedEndTime, dailyRate)" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const start = new Date(startTime);
    const end = new Date(plannedEndTime);

    if (end <= start) {
      return new Response(
        JSON.stringify({ error: "Waktu selesai harus lebih besar dari waktu mulai" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 1. Check Customer Blacklist
    const { data: customer, error: customerErr } = await supabaseClient
      .from("customers")
      .select("id, full_name, is_blacklisted, blacklist_reason")
      .eq("id", customerId)
      .single();

    if (customerErr || !customer) {
      return new Response(
        JSON.stringify({ error: "Pelanggan tidak ditemukan" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (customer.is_blacklisted) {
      return new Response(
        JSON.stringify({ 
          error: `Pemesanan DITOLAK: Pelanggan terdaftar dalam Daftar Hitam (Blacklist). Alasan: ${customer.blacklist_reason || 'Tidak ada alasan khusus'}` 
        }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Atomic Anti-Collision Check
    const { data: isAvailable, error: rpcErr } = await supabaseClient.rpc("check_vehicle_availability", {
      p_vehicle_id: vehicleId,
      p_start_time: startTime,
      p_end_time: plannedEndTime,
    });

    if (rpcErr) {
      return new Response(
        JSON.stringify({ error: "Gagal memvalidasi ketersediaan unit: " + rpcErr.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!isAvailable) {
      return new Response(
        JSON.stringify({ 
          error: "Jadwal Tumpang Tindih (Double-Booking Terdeteksi): Unit kendaraan sudah dipesan atau sedang dalam jadwal servis pada rentang tanggal tersebut." 
        }),
        { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 3. Calculate Duration & Amounts
    const diffHours = (end.getTime() - start.getTime()) / (1000 * 60 * 60);
    const durationDays = Math.max(1, Math.ceil(diffHours / 24));
    const baseAmount = durationDays * dailyRate;
    const totalAmount = baseAmount;

    // Generate Transaction Code: RNT-YYYYMMDD-XXXX
    const dateStr = start.toISOString().slice(0, 10).replace(/-/g, "");
    const randomSuffix = Math.floor(1000 + Math.random() * 9000);
    const transactionCode = `RNT-${dateStr}-${randomSuffix}`;

    // 4. Insert Rental Record
    const { data: rental, error: insertErr } = await supabaseClient
      .from("rentals")
      .insert({
        transaction_code: transactionCode,
        vehicle_id: vehicleId,
        customer_id: customerId,
        start_time: startTime,
        planned_end_time: plannedEndTime,
        daily_rate: dailyRate,
        duration_days: durationDays,
        base_amount: baseAmount,
        total_amount: totalAmount,
        down_payment: downPayment,
        deposit_amount: depositAmount,
        payment_status: downPayment > 0 ? "DOWN_PAYMENT" : "PENDING",
        rental_status: "BOOKED",
        notes,
        handled_by: handledBy,
      })
      .select()
      .single();

    if (insertErr) {
      return new Response(
        JSON.stringify({ error: "Gagal menyimpan reservasi: " + insertErr.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 5. Update Vehicle status to BOOKING if starting within 24 hours
    const now = new Date();
    const isStartingSoon = (start.getTime() - now.getTime()) <= 24 * 60 * 60 * 1000;
    if (isStartingSoon) {
      await supabaseClient
        .from("vehicles")
        .update({ status: "BOOKING" })
        .eq("id", vehicleId)
        .eq("status", "TERSEDIA");
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "Reservasi berhasil dibuat tanpa konflik jadwal",
        rental,
      }),
      { status: 201, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    return new Response(
      JSON.stringify({ error: message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
