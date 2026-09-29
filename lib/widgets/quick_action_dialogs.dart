import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'car_damage_inspector.dart';

class QuickActionDialogs {
  static final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  // 1. DIALOG SEWA / BOOKING BARU (Ctrl+N)
  static void showNewBookingDialog(BuildContext context, AppState state, {Vehicle? preselectedVehicle}) {
    Customer? selectedCustomer = state.customers.isNotEmpty ? state.customers.first : null;
    Vehicle? selectedVehicle = preselectedVehicle ?? (state.vehicles.where((v) => v.status == VehicleStatus.tersedia).firstOrNull);

    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 2));

    final dpController = TextEditingController(text: '0');
    final depositController = TextEditingController(text: '500000');
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final diffHours = endDate.difference(startDate).inHours;
          final durationDays = (diffHours / 24).ceil().clamp(1, 999);
          final dailyRate = selectedVehicle?.dailyRate ?? 0.0;
          final totalBaseAmount = durationDays * dailyRate;

          return Dialog(
            backgroundColor: AppTheme.surfaceCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.border),
            ),
            child: Container(
              width: 580,
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.add_shopping_cart_rounded, color: AppTheme.primary),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Registrasi Sewa / Booking Baru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                                Text('Pencatatan transaksi kasir cepat & akurat', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Customer Selection
                    const Text('Data Penyewa:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<Customer>(
                      initialValue: selectedCustomer,
                      dropdownColor: AppTheme.surfaceCard,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: state.customers.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Row(
                            children: [
                              Text(
                                c.fullName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: c.isBlacklisted ? AppTheme.danger : AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('(${c.phoneNumber})', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                              if (c.isBlacklisted) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.danger.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('BLACKLIST', style: TextStyle(fontSize: 10, color: AppTheme.danger, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setDlgState(() => selectedCustomer = val),
                    ),

                    if (selectedCustomer?.isBlacklisted == true) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.danger.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_rounded, color: AppTheme.danger, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'PERINGATAN BLACKLIST: ${selectedCustomer?.blacklistReason}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFFFCA5A5), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    // Vehicle Selection
                    const Text('Pilih Unit Armada:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<Vehicle>(
                      initialValue: selectedVehicle,
                      dropdownColor: AppTheme.surfaceCard,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: state.vehicles.map((v) {
                        final isAvailable = v.status == VehicleStatus.tersedia;
                        return DropdownMenuItem(
                          value: v,
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(color: Color(v.status.colorValue), shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${v.plateNumber} - ${v.brand} ${v.model} (${currencyFormat.format(v.dailyRate)}/hari)',
                                style: TextStyle(fontSize: 12, color: isAvailable ? AppTheme.textPrimary : AppTheme.textDim),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '[${v.status.label}]',
                                style: TextStyle(fontSize: 11, color: Color(v.status.colorValue), fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setDlgState(() => selectedVehicle = val),
                    ),

                    const SizedBox(height: 16),
                    // Duration & Dates
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Tanggal Mulai:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textPrimary)),
                              const SizedBox(height: 4),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: AppTheme.surfaceInput,
                                  foregroundColor: AppTheme.textPrimary,
                                  side: const BorderSide(color: AppTheme.border),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.calendar_today_rounded, size: 15, color: AppTheme.primary),
                                label: Text(DateFormat('dd/MM/yyyy HH:mm').format(startDate), style: const TextStyle(fontSize: 12)),
                                onPressed: () async {
                                  final d = await showDatePicker(
                                    context: ctx,
                                    initialDate: startDate,
                                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                                    lastDate: DateTime.now().add(const Duration(days: 90)),
                                  );
                                  if (d != null) {
                                    setDlgState(() => startDate = DateTime(d.year, d.month, d.day, startDate.hour, startDate.minute));
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Rencana Kembali:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textPrimary)),
                              const SizedBox(height: 4),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: AppTheme.surfaceInput,
                                  foregroundColor: AppTheme.textPrimary,
                                  side: const BorderSide(color: AppTheme.border),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.event_available_rounded, size: 15, color: AppTheme.success),
                                label: Text(DateFormat('dd/MM/yyyy HH:mm').format(endDate), style: const TextStyle(fontSize: 12)),
                                onPressed: () async {
                                  final d = await showDatePicker(
                                    context: ctx,
                                    initialDate: endDate,
                                    firstDate: startDate,
                                    lastDate: startDate.add(const Duration(days: 120)),
                                  );
                                  if (d != null) {
                                    setDlgState(() => endDate = DateTime(d.year, d.month, d.day, endDate.hour, endDate.minute));
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    // Payments
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: dpController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                            decoration: const InputDecoration(labelText: 'Uang Muka / DP (Rp)', hintText: '0'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: depositController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                            decoration: const InputDecoration(labelText: 'Deposit Jaminan (Rp)', hintText: '500000'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(labelText: 'Catatan Khusus / Keperluan', hintText: 'Tujuan perjalanan, acara khusus, dll'),
                    ),

                    const SizedBox(height: 16),
                    // Cost Summary Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceInput,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Durasi Sewa: $durationDays Hari', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                              Text('Tarif: ${currencyFormat.format(dailyRate)}/hari', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                            ],
                          ),
                          const Divider(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Biaya Pokok Sewa:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                              Text(
                                currencyFormat.format(totalBaseAmount),
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Batal', style: TextStyle(color: AppTheme.textMuted)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Simpan Transaksi Sewa', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            if (selectedCustomer == null || selectedVehicle == null) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih pelanggan dan kendaraan terlebih dahulu.')));
                              return;
                            }

                            final dp = double.tryParse(dpController.text) ?? 0;
                            final deposit = double.tryParse(depositController.text) ?? 0;

                            final errorMsg = state.createBooking(
                              customerId: selectedCustomer!.id,
                              vehicleId: selectedVehicle!.id,
                              startTime: startDate,
                              plannedEndTime: endDate,
                              dailyRate: selectedVehicle!.dailyRate,
                              downPayment: dp,
                              depositAmount: deposit,
                              notes: notesController.text.trim(),
                            );

                            if (errorMsg != null) {
                              showDialog(
                                context: ctx,
                                builder: (diagCtx) => AlertDialog(
                                  backgroundColor: AppTheme.surfaceCard,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppTheme.border)),
                                  title: const Row(
                                    children: [
                                      Icon(Icons.error_outline_rounded, color: AppTheme.danger),
                                      SizedBox(width: 8),
                                      Text('Gagal Membuat Sewa', style: TextStyle(color: AppTheme.textPrimary)),
                                    ],
                                  ),
                                  content: Text(errorMsg, style: const TextStyle(color: AppTheme.textSecondary)),
                                  actions: [TextButton(onPressed: () => Navigator.pop(diagCtx), child: const Text('Tutup'))],
                                ),
                              );
                            } else {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(backgroundColor: AppTheme.success, content: Text('Sewa/Booking berhasil disimpan!')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 2. DIALOG SERAH TERIMA (CHECK-OUT)
  static void showCheckoutDialog(BuildContext context, AppState state, Rental rental) {
    final vehicle = rental.vehicle;
    final odoController = TextEditingController(text: (vehicle?.odometerCurrent ?? 0).toString());
    int fuelLevel = 8; // 8/8 Full
    List<BodyDefectPoint> defects = [];
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => Dialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.border),
          ),
          child: Container(
            width: 720,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.accentPurple.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.key_rounded, color: AppTheme.accentPurple),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Formulir Serah Terima Unit (Check-Out) - ${rental.transactionCode}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                              Text('Armada: ${vehicle?.plateNumber} (${vehicle?.brand} ${vehicle?.model})',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                            ],
                          ),
                        ],
                      ),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted)),
                    ],
                  ),
                  const Divider(height: 20),

                  // Odometer & Fuel Level
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: odoController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Odometer Awal (km)',
                            suffixText: 'km',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Level Bahan Bakar Awal: $fuelLevel/8 (${(fuelLevel / 8 * 100).toInt()}%)',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textPrimary)),
                            Slider(
                              value: fuelLevel.toDouble(),
                              min: 1,
                              max: 8,
                              divisions: 7,
                              activeColor: AppTheme.primary,
                              label: '$fuelLevel/8',
                              onChanged: (val) => setDlgState(() => fuelLevel = val.toInt()),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  // Visual Body Inspector
                  CarDamageInspector(
                    existingDefects: defects,
                    onDefectsChanged: (d) => defects = d,
                    title: 'Inspeksi Titik Cacat Bodi Awal (Check-Out)',
                  ),

                  const SizedBox(height: 16),
                  TextField(
                    controller: notesController,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Catatan Kondisi Fisik Kendaraan',
                      hintText: 'Contoh: Kunci serep disertakan, ban cadangan aman, dongkrak lengkap',
                    ),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: AppTheme.textMuted))),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                        label: const Text('Konfirmasi Serah Terima (Set DISEWA)', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          final odo = int.tryParse(odoController.text) ?? vehicle?.odometerCurrent ?? 0;
                          final err = state.processCheckOut(
                            rentalId: rental.id,
                            odometerStart: odo,
                            fuelLevel: fuelLevel,
                            defects: defects,
                            notes: notesController.text.trim(),
                          );

                          if (err != null) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                          } else {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(backgroundColor: AppTheme.accentPurple, content: Text('Unit berhasil diserahterimakan! Status: DISEWA.')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 3. DIALOG PENGEMBALIAN (CHECK-IN) & SETTLEMENT
  static void showCheckinDialog(BuildContext context, AppState state, Rental rental) {
    final vehicle = rental.vehicle;
    final checkoutInsp = state.inspections.where((i) => i.rentalId == rental.id && i.type == 'CHECK_OUT').firstOrNull;
    final startOdo = checkoutInsp?.odometer ?? vehicle?.odometerCurrent ?? 0;
    final startFuel = checkoutInsp?.fuelLevel ?? 8;

    final odoController = TextEditingController(text: (startOdo + 150).toString());
    int fuelLevel = startFuel;
    List<BodyDefectPoint> defects = [];
    final damageFeeController = TextEditingController(text: '0');
    final notesController = TextEditingController();

    DateTime returnTime = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final odoEnd = int.tryParse(odoController.text) ?? startOdo;
          final damageFee = double.tryParse(damageFeeController.text) ?? 0.0;

          // Overtime calculation
          double overtimeHours = 0;
          double overtimeFee = 0;
          final diffMinutes = returnTime.difference(rental.plannedEndTime).inMinutes;
          if (diffMinutes > 60) {
            overtimeHours = ((diffMinutes - 60) / 60).ceilToDouble();
            if (overtimeHours > 5) {
              overtimeFee = rental.dailyRate;
            } else {
              overtimeFee = overtimeHours * (rental.dailyRate * 0.10);
            }
          }

          // Fuel shortfall fee
          final fuelDiff = startFuel - fuelLevel;
          final fuelFee = fuelDiff > 0 ? fuelDiff * 35000.0 : 0.0;

          // Settlement
          final totalAmount = rental.baseAmount + overtimeFee + fuelFee + damageFee;
          final totalPrepaid = rental.downPayment + rental.depositAmount;
          double netDue = totalAmount - totalPrepaid;
          double refundDeposit = 0;
          if (netDue < 0) {
            refundDeposit = netDue.abs();
            netDue = 0;
          }

          return Dialog(
            backgroundColor: AppTheme.surfaceCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.border),
            ),
            child: Container(
              width: 760,
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.assignment_turned_in_rounded, color: AppTheme.success),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Pengembalian & Kalkulasi Denda (Check-In) - ${rental.transactionCode}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                                Text('Penyewa: ${rental.customer?.fullName} | Armada: ${vehicle?.plateNumber}',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                              ],
                            ),
                          ],
                        ),
                        IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted)),
                      ],
                    ),
                    const Divider(height: 20),

                    // Odometer & Fuel Level
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: odoController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                            onChanged: (_) => setDlgState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Odometer Akhir (Awal: $startOdo km)',
                              suffixText: 'km',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('BBM Akhir: $fuelLevel/8 (Awal: $startFuel/8)',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textPrimary)),
                              Slider(
                                value: fuelLevel.toDouble(),
                                min: 1,
                                max: 8,
                                divisions: 7,
                                activeColor: AppTheme.success,
                                label: '$fuelLevel/8',
                                onChanged: (val) => setDlgState(() => fuelLevel = val.toInt()),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Overtime Warning Box
                    if (overtimeHours > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_filled_rounded, color: AppTheme.warning, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'KETERLAMBATAN TERDETEKSI: Melewati toleransi 60 menit! Keterlambatan: ${overtimeHours.toStringAsFixed(0)} Jam. Denda: ${currencyFormat.format(overtimeFee)} ${overtimeHours > 5 ? '(Tarif 1 Hari Penuh)' : ''}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFDE68A)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    // Damage Inspector
                    CarDamageInspector(
                      existingDefects: defects,
                      onDefectsChanged: (d) => defects = d,
                      title: 'Inspeksi Cacat Bodi Baru saat Pengembalian',
                    ),

                    const SizedBox(height: 12),
                    TextField(
                      controller: damageFeeController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      onChanged: (_) => setDlgState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Biaya Perbaikan Kerusakan Bodi Baru (Rp)',
                        hintText: '0 jika tidak ada lecet/rusak baru',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Catatan Pengembalian',
                        hintText: 'Kondisi kendaraan saat diterima',
                      ),
                    ),

                    const SizedBox(height: 16),
                    // Settlement Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceInput,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Rincian Settlement Pembayaran & Deposit',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                          const SizedBox(height: 8),
                          _settleRow('Biaya Pokok Sewa (${rental.durationDays} hari)', currencyFormat.format(rental.baseAmount)),
                          if (overtimeFee > 0)
                            _settleRow('Denda Overtime (${overtimeHours.toStringAsFixed(0)} Jam)', currencyFormat.format(overtimeFee), color: AppTheme.warning),
                          if (fuelFee > 0)
                            _settleRow('Selisih BBM Kurang ($fuelDiff bar)', currencyFormat.format(fuelFee), color: AppTheme.warning),
                          if (damageFee > 0)
                            _settleRow('Biaya Kerusakan Bodi', currencyFormat.format(damageFee), color: AppTheme.danger),
                          const Divider(height: 12),
                          _settleRow('TOTAL TAGIHAN AKHIR', currencyFormat.format(totalAmount), isBold: true, color: AppTheme.textPrimary),
                          _settleRow('Uang Muka (DP) Dibayar', '- ${currencyFormat.format(rental.downPayment)}'),
                          _settleRow('Deposit Jaminan Tersedia', '- ${currencyFormat.format(rental.depositAmount)}'),
                          const Divider(height: 12),
                          if (refundDeposit > 0)
                            _settleRow('PENGEMBALIAN DEPOSIT KE PELANGGAN', currencyFormat.format(refundDeposit), isBold: true, color: AppTheme.success),
                          if (netDue > 0)
                            _settleRow('SISA KEKURANGAN HARUS DIBAYAR', currencyFormat.format(netDue), isBold: true, color: AppTheme.danger),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: AppTheme.textMuted))),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.done_all_rounded, size: 18),
                          label: const Text('Tutup Sewa & Kembalikan Unit (TERSEDIA)', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            if (odoEnd < startOdo) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Odometer akhir tidak boleh < $startOdo km')));
                              return;
                            }

                            state.processCheckIn(
                              rentalId: rental.id,
                              odometerEnd: odoEnd,
                              fuelLevelEnd: fuelLevel,
                              actualEndTime: returnTime,
                              defectsEnd: defects,
                              damageFee: damageFee,
                              notes: notesController.text.trim(),
                            );

                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(backgroundColor: AppTheme.success, content: Text('Check-in selesai! Invoice tagihan & struk siap dicetak.')),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget _settleRow(String title, String val, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? AppTheme.textPrimary : AppTheme.textSecondary,
            ),
          ),
          Text(
            val,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? (isBold ? AppTheme.textPrimary : AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
