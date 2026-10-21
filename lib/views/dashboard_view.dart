import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/gantt_timeline_view.dart';
import '../widgets/quick_action_dialogs.dart';
import '../widgets/thermal_receipt_dialog.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _activeSubView = 0; // 0: Transaksi Kasir, 1: Kalender Ketersediaan (Gantt)

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    // Fleet Counters
    final countTersedia = state.vehicles.where((v) => v.status == VehicleStatus.tersedia).length;
    final countBooking = state.vehicles.where((v) => v.status == VehicleStatus.booking).length;
    final countDisewa = state.vehicles.where((v) => v.status == VehicleStatus.disewa).length;
    final countPerawatan = state.vehicles.where((v) => v.status == VehicleStatus.perawatan).length;

    // Collect alerts
    final redAlerts = <Map<String, dynamic>>[];
    final yellowAlerts = <Map<String, dynamic>>[];

    for (final v in state.vehicles) {
      final h = state.getHealthForVehicle(v.id);
      for (final a in h.alerts) {
        if (a.level == HealthLevel.merah) {
          redAlerts.add({'vehicle': v, 'alert': a});
        } else if (a.level == HealthLevel.kuning) {
          yellowAlerts.add({'vehicle': v, 'alert': a});
        }
      }
    }

    final totalAlerts = redAlerts.length + yellowAlerts.length;
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 24, vertical: isMobile ? 14 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Title & Quick Primary Action (Responsive)
            if (isMobile) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.currentRole == UserRole.mechanic
                        ? 'Pusat Bengkel & Perawatan'
                        : state.currentRole == UserRole.frontDesk
                            ? 'Pusat Kasir & Front Desk'
                            : 'Pusat Operasional Eksekutif',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    state.currentRole == UserRole.mechanic
                        ? 'Pengawasan kesehatan mesin, ambang batas odometer & servis'
                        : state.currentRole == UserRole.frontDesk
                            ? 'Sirkulasi rental harian, serah terima, dan pengembalian unit'
                            : 'Ringkasan armada harian, sirkulasi sewa, dan kontrol armada',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppTheme.surfaceCard,
                            foregroundColor: AppTheme.textSecondary,
                            side: const BorderSide(color: AppTheme.border),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Refresh', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          onPressed: () {
                            state.evaluateAllMaintenance();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Data berhasil diperbarui'), duration: Duration(seconds: 1)),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: state.currentRole == UserRole.mechanic ? AppTheme.warning : AppTheme.primary,
                            foregroundColor: state.currentRole == UserRole.mechanic ? Colors.black : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          icon: Icon(state.currentRole == UserRole.mechanic ? Icons.build_circle_rounded : Icons.add_rounded, size: 16),
                          label: Text(
                            state.currentRole == UserRole.mechanic ? 'Cek Servis' : 'Sewa Baru',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          onPressed: () {
                            if (state.currentRole == UserRole.mechanic) {
                              state.setTabIndex(0);
                            } else {
                              QuickActionDialogs.showNewBookingDialog(context, state);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.currentRole == UserRole.mechanic
                            ? 'Pusat Bengkel & Perawatan'
                            : state.currentRole == UserRole.frontDesk
                                ? 'Pusat Kasir & Front Desk'
                                : 'Pusat Operasional Eksekutif',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        state.currentRole == UserRole.mechanic
                            ? 'Monitoring kesehatan mesin, ambang batas odometer, dan antrean servis armada'
                            : state.currentRole == UserRole.frontDesk
                                ? 'Sirkulasi rental harian, serah terima, dan pengembalian unit pelanggan'
                                : 'Ringkasan armada harian, sirkulasi sewa, dan pengawasan kondisi kendaraan',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 10,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppTheme.surfaceCard,
                          foregroundColor: const Color(0xFF8B5CF6),
                          side: const BorderSide(color: Color(0xFF8B5CF6)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.psychology_rounded, size: 16),
                        label: const Text('AI & Analitik ML', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () => state.setTabIndex(state.currentRole == UserRole.manager ? 5 : 4),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppTheme.surfaceCard,
                          foregroundColor: AppTheme.textSecondary,
                          side: const BorderSide(color: AppTheme.border),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Refresh (F5)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        onPressed: () {
                          state.evaluateAllMaintenance();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Data berhasil diperbarui'), duration: Duration(seconds: 1)),
                          );
                        },
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: state.currentRole == UserRole.mechanic ? AppTheme.warning : AppTheme.primary,
                          foregroundColor: state.currentRole == UserRole.mechanic ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        icon: Icon(state.currentRole == UserRole.mechanic ? Icons.build_circle_rounded : Icons.add_rounded, size: 18),
                        label: Text(
                          state.currentRole == UserRole.mechanic ? 'Buka Jadwal Servis' : 'Sewa Baru (Ctrl+N)',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        onPressed: () {
                          if (state.currentRole == UserRole.mechanic) {
                            state.setTabIndex(0);
                          } else {
                            QuickActionDialogs.showNewBookingDialog(context, state);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),

            // Health Alert Banner - Compact & Uncluttered
            if (totalAlerts > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: redAlerts.isNotEmpty
                      ? AppTheme.danger.withValues(alpha: 0.12)
                      : AppTheme.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: redAlerts.isNotEmpty
                        ? AppTheme.danger.withValues(alpha: 0.4)
                        : AppTheme.warning.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      redAlerts.isNotEmpty ? Icons.warning_rounded : Icons.info_outline_rounded,
                      color: redAlerts.isNotEmpty ? AppTheme.danger : AppTheme.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        redAlerts.isNotEmpty
                            ? 'Pemberitahuan Servis: ${redAlerts.length} unit jatuh tempo jadwal bengkel & dikunci sementara.'
                            : 'Pemberitahuan Siaga: ${yellowAlerts.length} unit mendekati batas kilometer servis berkala.',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: redAlerts.isNotEmpty ? const Color(0xFFFCA5A5) : const Color(0xFFFCD34D),
                        ),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        foregroundColor: redAlerts.isNotEmpty ? const Color(0xFFFCA5A5) : const Color(0xFFFCD34D),
                      ),
                      onPressed: () => state.setTabIndex(3),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Servis', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          SizedBox(width: 2),
                          Icon(Icons.arrow_forward_rounded, size: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 4 Clean KPI Cards (Tailored per User Role)
            if (state.currentRole == UserRole.mechanic) ...[
              if (isMobile) ...[
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.35,
                  children: [
                    _kpiCard(
                      title: 'Jatuh Tempo (Merah)',
                      count: redAlerts.length.toString(),
                      desc: 'Odo / limit lewat',
                      color: AppTheme.danger,
                      icon: Icons.cancel_rounded,
                      onTap: () => state.setTabIndex(0),
                    ),
                    _kpiCard(
                      title: 'Siaga Servis (Kuning)',
                      count: yellowAlerts.length.toString(),
                      desc: 'Mendekati limit',
                      color: AppTheme.warning,
                      icon: Icons.warning_rounded,
                      onTap: () => state.setTabIndex(0),
                    ),
                    _kpiCard(
                      title: 'Sedang di Bengkel',
                      count: countPerawatan.toString(),
                      desc: 'Unit perbaikan',
                      color: AppTheme.accentPurple,
                      icon: Icons.build_circle_outlined,
                      onTap: () => state.setTabIndex(0),
                    ),
                    _kpiCard(
                      title: 'Kondisi Prima',
                      count: (state.vehicles.length - redAlerts.length - yellowAlerts.length).clamp(0, 999).toString(),
                      desc: 'Mesin aman jalan',
                      color: AppTheme.success,
                      icon: Icons.check_circle_outline_rounded,
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    _kpiCard(
                      title: 'Jatuh Tempo (Merah)',
                      count: redAlerts.length.toString(),
                      desc: 'Odometer / limit lewat (Auto-Lock)',
                      color: AppTheme.danger,
                      icon: Icons.cancel_rounded,
                      isExpanded: true,
                      onTap: () => state.setTabIndex(0),
                    ),
                    const SizedBox(width: 12),
                    _kpiCard(
                      title: 'Siaga Servis (Kuning)',
                      count: yellowAlerts.length.toString(),
                      desc: 'Mendekati limit (<= 500 km)',
                      color: AppTheme.warning,
                      icon: Icons.warning_rounded,
                      isExpanded: true,
                      onTap: () => state.setTabIndex(0),
                    ),
                    const SizedBox(width: 12),
                    _kpiCard(
                      title: 'Sedang di Bengkel',
                      count: countPerawatan.toString(),
                      desc: 'Unit dalam proses perbaikan',
                      color: AppTheme.accentPurple,
                      icon: Icons.build_circle_outlined,
                      isExpanded: true,
                      onTap: () => state.setTabIndex(0),
                    ),
                    const SizedBox(width: 12),
                    _kpiCard(
                      title: 'Armada Prima',
                      count: (state.vehicles.length - redAlerts.length - yellowAlerts.length).clamp(0, 999).toString(),
                      desc: 'Mesin siap jalan aman',
                      color: AppTheme.success,
                      icon: Icons.check_circle_outline_rounded,
                      isExpanded: true,
                    ),
                  ],
                ),
              ],
            ] else ...[
              if (isMobile) ...[
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.35,
                  children: [
                    _kpiCard(
                      title: 'Armada Tersedia',
                      count: countTersedia.toString(),
                      desc: 'Siap sewa di garasi',
                      color: AppTheme.success,
                      icon: Icons.check_circle_outline_rounded,
                    ),
                    _kpiCard(
                      title: 'Booking Terjadwal',
                      count: countBooking.toString(),
                      desc: 'Pesanan mendatang',
                      color: AppTheme.primary,
                      icon: Icons.calendar_today_rounded,
                    ),
                    _kpiCard(
                      title: 'Sedang Disewa',
                      count: countDisewa.toString(),
                      desc: 'Digunakan penyewa',
                      color: AppTheme.accentPurple,
                      icon: Icons.car_rental_rounded,
                    ),
                    _kpiCard(
                      title: 'Dalam Perawatan',
                      count: countPerawatan.toString(),
                      desc: 'Bengkel / inspeksi',
                      color: AppTheme.warning,
                      icon: Icons.build_circle_outlined,
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    _kpiCard(
                      title: 'Armada Tersedia',
                      count: countTersedia.toString(),
                      desc: 'Siap sewa di garasi',
                      color: AppTheme.success,
                      icon: Icons.check_circle_outline_rounded,
                      isExpanded: true,
                    ),
                    const SizedBox(width: 12),
                    _kpiCard(
                      title: 'Booking Terjadwal',
                      count: countBooking.toString(),
                      desc: 'Pesanan mendatang',
                      color: AppTheme.primary,
                      icon: Icons.calendar_today_rounded,
                      isExpanded: true,
                    ),
                    const SizedBox(width: 12),
                    _kpiCard(
                      title: 'Sedang Disewa',
                      count: countDisewa.toString(),
                      desc: 'Digunakan penyewa',
                      color: AppTheme.accentPurple,
                      icon: Icons.car_rental_rounded,
                      isExpanded: true,
                    ),
                    const SizedBox(width: 12),
                    _kpiCard(
                      title: 'Dalam Perawatan',
                      count: countPerawatan.toString(),
                      desc: 'Bengkel / inspeksi',
                      color: AppTheme.warning,
                      icon: Icons.build_circle_outlined,
                      isExpanded: true,
                    ),
                  ],
                ),
              ],
            ],
            const SizedBox(height: 18),

            // Segmented Switcher for Clean UX
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _subViewTab(
                      index: 0,
                      label: state.currentRole == UserRole.mechanic
                          ? 'Antrean Servis Bengkel (${redAlerts.length + yellowAlerts.length})'
                          : 'Sewa Berjalan (${state.rentals.where((r) => r.rentalStatus != 'COMPLETED').length})',
                      icon: state.currentRole == UserRole.mechanic ? Icons.handyman_rounded : Icons.receipt_long_rounded,
                    ),
                    const SizedBox(width: 4),
                    _subViewTab(
                      index: 1,
                      label: 'Matriks Ketersediaan (Gantt 14 Hari)',
                      icon: Icons.calendar_view_week_rounded,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Main Active View Content
            if (_activeSubView == 0) ...[
              if (state.currentRole == UserRole.mechanic) ...[
                _buildMechanicQueue(context, state, redAlerts, yellowAlerts, isMobile),
              ] else ...[
                // Active Transactions + Fast Info
                Builder(
                  builder: (context) {
                    final activeRentalsWidget = Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Row(
                                  children: [
                                    Icon(Icons.directions_car_rounded, size: 18, color: AppTheme.primary),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Daftar Sewa Aktif & Siap Serah Terima',
                                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              TextButton(
                                onPressed: () => state.setTabIndex(2), // jump to rentals
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(isMobile ? 'Kelola' : 'Kelola Transaksi', style: const TextStyle(fontSize: 12)),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_forward_rounded, size: 14),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          if (state.rentals.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 36),
                              child: Center(
                                child: Text('Belum ada transaksi sewa aktif saat ini.', style: TextStyle(color: AppTheme.textMuted)),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: state.rentals.take(5).length,
                              separatorBuilder: (_, _) => const Divider(height: 14),
                              itemBuilder: (context, idx) {
                                final r = state.rentals[idx];
                                final isActive = r.rentalStatus == 'ACTIVE';
                                final isBooked = r.rentalStatus == 'BOOKED';

                                Color statusColor = isActive
                                    ? AppTheme.accentPurple
                                    : isBooked
                                        ? AppTheme.primary
                                        : AppTheme.success;

                                if (isMobile) {
                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceInput,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppTheme.border),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  r.transactionCode,
                                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: statusColor.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                                  ),
                                                  child: Text(
                                                    r.rentalStatus,
                                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.print_outlined, size: 18, color: AppTheme.textMuted),
                                              tooltip: 'Cetak Struk',
                                              visualDensity: VisualDensity.compact,
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: () => showDialog(
                                                context: context,
                                                builder: (_) => ThermalReceiptDialog(rental: r),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.person_outline_rounded, size: 14, color: AppTheme.textMuted),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                '${r.customer?.fullName ?? '-'} • ${r.customer?.phoneNumber ?? ''}',
                                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: AppTheme.surfaceCard,
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: AppTheme.border),
                                              ),
                                              child: Text(
                                                r.vehicle?.plateNumber ?? '-',
                                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10, fontFamily: 'monospace', color: AppTheme.textPrimary),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '${r.vehicle?.brand ?? ''} ${r.vehicle?.model ?? ''}',
                                                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (r.rentalStatus == 'BOOKED' || r.rentalStatus == 'ACTIVE') ...[
                                          const SizedBox(height: 10),
                                          SizedBox(
                                            width: double.infinity,
                                            child: r.rentalStatus == 'BOOKED'
                                                ? ElevatedButton.icon(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: AppTheme.accentPurple,
                                                      foregroundColor: Colors.white,
                                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                    ),
                                                    icon: const Icon(Icons.key_rounded, size: 14),
                                                    label: const Text('Check-Out Unit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                                    onPressed: () => QuickActionDialogs.showCheckoutDialog(context, state, r),
                                                  )
                                                : ElevatedButton.icon(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: AppTheme.success,
                                                      foregroundColor: Colors.white,
                                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                    ),
                                                    icon: const Icon(Icons.assignment_turned_in_rounded, size: 14),
                                                    label: const Text('Check-In Unit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                                    onPressed: () => QuickActionDialogs.showCheckinDialog(context, state, r),
                                                  ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      // Status icon container
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          isActive
                                              ? Icons.car_rental_rounded
                                              : isBooked
                                                  ? Icons.bookmark_added_rounded
                                                  : Icons.check_circle_outline_rounded,
                                          color: statusColor,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Transaction Info
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  r.transactionCode,
                                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: statusColor.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                                  ),
                                                  child: Text(
                                                    r.rentalStatus,
                                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${r.customer?.fullName ?? '-'} • ${r.customer?.phoneNumber ?? ''}',
                                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Vehicle
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppTheme.surfaceInput,
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: AppTheme.border),
                                              ),
                                              child: Text(
                                                r.vehicle?.plateNumber ?? '-',
                                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, fontFamily: 'monospace', color: AppTheme.textPrimary),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${r.vehicle?.brand ?? ''} ${r.vehicle?.model ?? ''}',
                                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Actions
                                      Wrap(
                                        spacing: 6,
                                        children: [
                                          if (r.rentalStatus == 'BOOKED')
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppTheme.accentPurple,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                visualDensity: VisualDensity.compact,
                                              ),
                                              onPressed: () => QuickActionDialogs.showCheckoutDialog(context, state, r),
                                              child: const Text('Check-Out', style: TextStyle(fontSize: 11)),
                                            ),
                                          if (r.rentalStatus == 'ACTIVE')
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppTheme.success,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                visualDensity: VisualDensity.compact,
                                              ),
                                              onPressed: () => QuickActionDialogs.showCheckinDialog(context, state, r),
                                              child: const Text('Check-In', style: TextStyle(fontSize: 11)),
                                            ),
                                          IconButton(
                                            icon: const Icon(Icons.print_outlined, size: 18, color: AppTheme.textMuted),
                                            tooltip: 'Cetak Struk Termal',
                                            visualDensity: VisualDensity.compact,
                                            onPressed: () => showDialog(
                                              context: context,
                                              builder: (_) => ThermalReceiptDialog(rental: r),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    );

                  // Right: Quick Operations Snapshot
                  final operationsSnapshotWidget = Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.analytics_outlined, size: 18, color: AppTheme.primary),
                              SizedBox(width: 8),
                              Text(
                                'Statistik Operasional',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _statRow('Total Armada Terdaftar', '${state.vehicles.length} Unit', Icons.directions_car_rounded),
                          _statRow('Pelanggan Terdaftar', '${state.customers.length} Orang', Icons.people_outline_rounded),
                          _statRow(
                            'Estimasi Omset Sewa',
                            currency.format(state.rentals.fold(0.0, (sum, r) => sum + r.baseAmount)),
                            Icons.monetization_on_outlined,
                            isAmount: true,
                          ),
                          _statRow(
                            'Tingkat Utilisasi',
                            '${((countDisewa + countBooking) / (state.vehicles.isEmpty ? 1 : state.vehicles.length) * 100).toInt()}%',
                            Icons.trending_up_rounded,
                          ),
                          const Divider(height: 20),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceInput,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.lightbulb_outline_rounded, size: 14, color: AppTheme.warning),
                                    SizedBox(width: 6),
                                    Text('Tips Kasir', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.warning)),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Gunakan Ctrl+N untuk transaksi baru cepat. Cetak struk kasir termal langsung setelah serah terima unit.',
                                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );

                    if (isMobile) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          activeRentalsWidget,
                          const SizedBox(height: 14),
                          operationsSnapshotWidget,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: activeRentalsWidget),
                        const SizedBox(width: 14),
                        Expanded(flex: 3, child: operationsSnapshotWidget),
                      ],
                    );
                  },
                ),
              ],
            ] else ...[
              // Gantt Matrix View
              SizedBox(
                height: 380,
                child: GanttTimelineView(
                  state: state,
                  onVehicleSelected: (v) {
                    state.selectVehicle(v);
                    state.setTabIndex(1);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _subViewTab({required int index, required String label, required IconData icon}) {
    final isSelected = _activeSubView == index;
    return InkWell(
      onTap: () => setState(() => _activeSubView = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: isSelected ? Colors.white : AppTheme.textMuted),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard({
    required String title,
    required String count,
    required String desc,
    required Color color,
    required IconData icon,
    bool isExpanded = false,
    VoidCallback? onTap,
  }) {
    Widget card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            count,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            style: const TextStyle(fontSize: 11, color: AppTheme.textDim),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: card,
        ),
      );
    }

    return isExpanded ? Expanded(child: card) : card;
  }

  Widget _statRow(String label, String value, IconData icon, {bool isAmount = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isAmount ? AppTheme.success : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMechanicQueue(
    BuildContext context,
    AppState state,
    List<Map<String, dynamic>> redAlerts,
    List<Map<String, dynamic>> yellowAlerts,
    bool isMobile,
  ) {
    final allAlerts = [...redAlerts, ...yellowAlerts];

    final queueWidget = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.handyman_rounded, size: 18, color: AppTheme.warning),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Prioritas Servis & Bengkel Armada',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              TextButton(
                onPressed: () => state.setTabIndex(0),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  visualDensity: VisualDensity.compact,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(isMobile ? 'Jadwal Servis' : 'Buka Jadwal Servis Lengkap', style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, size: 14),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          if (allAlerts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 42, color: AppTheme.success.withValues(alpha: 0.6)),
                    const SizedBox(height: 10),
                    const Text('Semua mesin armada saat ini dalam kondisi prima & aman jalan!', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: allAlerts.length,
              separatorBuilder: (_, _) => const Divider(height: 14),
              itemBuilder: (context, idx) {
                final item = allAlerts[idx];
                final Vehicle v = item['vehicle'];
                final MaintenanceAlert a = item['alert'];
                final isRed = a.level == HealthLevel.merah;
                final color = isRed ? AppTheme.danger : AppTheme.warning;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceInput,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(isRed ? Icons.cancel_rounded : Icons.warning_rounded, color: color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  v.plateNumber,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 13, color: AppTheme.textPrimary),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    v.displayName,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pekerjaan: ${a.serviceType} • Odometer: ${NumberFormat('#,###').format(v.odometerCurrent)} km',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isRed
                                  ? 'STATUS: JATUH TEMPO (${a.kmRemaining != null ? 'Terlewati ${a.kmRemaining!.abs()} km' : ''}) • Kunci Unit'
                                  : 'STATUS: SIAGA SERVIS (${a.kmRemaining != null ? 'Sisa ${a.kmRemaining} km' : ''})',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: () => state.setTabIndex(0),
                        child: const Text('Kerjakan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );

    final mechanicTipsWidget = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.build_rounded, size: 18, color: AppTheme.warning),
              SizedBox(width: 8),
              Text(
                'Status Bengkel & Armada',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _statRow('Unit Harus Servis', '${redAlerts.length} Mobil', Icons.dangerous_rounded),
          _statRow('Mendekati Batas', '${yellowAlerts.length} Mobil', Icons.warning_amber_rounded),
          _statRow('Sedang Dikerjakan', '${state.vehicles.where((v) => v.status == VehicleStatus.perawatan).length} Mobil', Icons.construction_rounded),
          _statRow('Kondisi Prima Siap Jalan', '${(state.vehicles.length - redAlerts.length - yellowAlerts.length).clamp(0, 999)} Mobil', Icons.thumb_up_alt_rounded),
          const Divider(height: 20),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceInput,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.primary),
                    SizedBox(width: 6),
                    Text('Pedoman Mekanik', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'Unit berstatus Merah otomatis dikunci dari sistem sewa sampai mekanik menyelesaikan servis dan memulihkannya ke Tersedia.',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          queueWidget,
          const SizedBox(height: 14),
          mechanicTipsWidget,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 6, child: queueWidget),
        const SizedBox(width: 14),
        Expanded(flex: 3, child: mechanicTipsWidget),
      ],
    );
  }
}
