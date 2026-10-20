import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class ReportsView extends StatelessWidget {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final totalRevenue = state.rentals.fold(0.0, (sum, r) => sum + r.totalAmount);
    final totalOvertime = state.rentals.fold(0.0, (sum, r) => sum + r.overtimeFee);
    final totalDamage = state.rentals.fold(0.0, (sum, r) => sum + r.damageFee);
    const estimatedMaintenanceCost = 750000.0;
    final netProfit = totalRevenue - estimatedMaintenanceCost;

    final isMobile = MediaQuery.of(context).size.width < 800;

    final activeRentals = state.rentals.where((r) => r.rentalStatus == 'ACTIVE').toList();
    final bookedRentals = state.rentals.where((r) => r.rentalStatus == 'BOOKED').toList();
    final completedRentals = state.rentals.where((r) => r.rentalStatus == 'COMPLETED').toList();

    final countTersedia = state.vehicles.where((v) => v.status == VehicleStatus.tersedia).length;
    final countDisewa = state.vehicles.where((v) => v.status == VehicleStatus.disewa).length;
    final countBooking = state.vehicles.where((v) => v.status == VehicleStatus.booking).length;
    final countPerawatan = state.vehicles.where((v) => v.status == VehicleStatus.perawatan).length;
    final totalVehicles = state.vehicles.isEmpty ? 1 : state.vehicles.length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Laporan Finansial & Operasional',
                        style: TextStyle(
                          fontSize: isMobile ? 20 : 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Ringkasan arus kas sewa, margin profitabilitas, dan tingkat utilisasi armada',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                if (!isMobile)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    icon: state.isSyncing
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                        : const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Sinkronkan Supabase', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: state.isSyncing ? null : () => state.syncWithSupabase(),
                  ),
              ],
            ),
            const SizedBox(height: 18),

            // Financial Metrics Cards
            if (isMobile) ...[
              Row(
                children: [
                  _metricCard('Total Omset', currency.format(totalRevenue), 'Pendapatan kotor', AppTheme.success, Icons.monetization_on_rounded, isMobile: true),
                  const SizedBox(width: 10),
                  _metricCard('Denda & Biaya', currency.format(totalOvertime + totalDamage), 'Overtime/Kerusakan', AppTheme.primary, Icons.add_chart_rounded, isMobile: true),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _metricCard('Estimasi Servis', currency.format(estimatedMaintenanceCost), 'Perawatan armada', AppTheme.warning, Icons.handyman_rounded, isMobile: true),
                  const SizedBox(width: 10),
                  _metricCard('Margin Bersih', currency.format(netProfit), 'Profitabilitas bersih', AppTheme.accentPurple, Icons.savings_rounded, isMobile: true),
                ],
              ),
            ] else
              Row(
                children: [
                  _metricCard('Total Omset Sewa', currency.format(totalRevenue), 'Pendapatan kotor', AppTheme.success, Icons.monetization_on_rounded),
                  const SizedBox(width: 12),
                  _metricCard('Denda & Surcharge', currency.format(totalOvertime + totalDamage), 'Overtime & Kerusakan', AppTheme.primary, Icons.add_chart_rounded),
                  const SizedBox(width: 12),
                  _metricCard('Estimasi Biaya Servis', currency.format(estimatedMaintenanceCost), 'Perawatan & bengkel', AppTheme.warning, Icons.handyman_rounded),
                  const SizedBox(width: 12),
                  _metricCard('Estimasi Margin Bersih', currency.format(netProfit), 'Profitabilitas bersih', AppTheme.accentPurple, Icons.savings_rounded),
                ],
              ),
            const SizedBox(height: 20),

            // Revenue Breakdown & Utilization Cards
            if (isMobile) ...[
              _buildRevenueBreakdownCard(currency, activeRentals, bookedRentals, completedRentals),
              const SizedBox(height: 14),
              _buildFleetUtilizationCard(totalVehicles, countTersedia, countDisewa, countBooking, countPerawatan),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: _buildRevenueBreakdownCard(currency, activeRentals, bookedRentals, completedRentals),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: _buildFleetUtilizationCard(totalVehicles, countTersedia, countDisewa, countBooking, countPerawatan),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),

            // Subtle Live Supabase Cloud Sync Status Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Icon(
                    state.isSyncing
                        ? Icons.sync_rounded
                        : (SupabaseService().isConnected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded),
                    color: SupabaseService().isConnected ? AppTheme.success : AppTheme.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.isSyncing
                              ? 'Sedang menyinkronkan data dengan Supabase...'
                              : (state.lastSyncTime != null
                                  ? 'Cloud Backend: Terhubung • Terakhir disinkronkan: ${DateFormat('dd MMM yyyy, HH:mm:ss').format(state.lastSyncTime!)}'
                                  : 'Cloud Backend: Offline • Data disimpan secara lokal di memori'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                        ),
                        if (state.syncError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Peringatan: ${state.syncError}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.danger),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: state.isSyncing
                        ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                        : const Icon(Icons.refresh_rounded, size: 14),
                    label: const Text('Sinkronkan', style: TextStyle(fontSize: 11)),
                    onPressed: state.isSyncing ? null : () => state.syncWithSupabase(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueBreakdownCard(
    NumberFormat currency,
    List<Rental> activeRentals,
    List<Rental> bookedRentals,
    List<Rental> completedRentals,
  ) {
    final activeSum = activeRentals.fold(0.0, (s, r) => s + r.totalAmount);
    final bookedSum = bookedRentals.fold(0.0, (s, r) => s + r.totalAmount);
    final completedSum = completedRentals.fold(0.0, (s, r) => s + r.totalAmount);

    return Container(
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
              Icon(Icons.pie_chart_outline_rounded, size: 18, color: AppTheme.primary),
              SizedBox(width: 8),
              Text(
                'Rincian Transaksi & Arus Kas Sewa',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _breakdownRow(
            'Sewa Berjalan (Active)',
            '${activeRentals.length} Transaksi',
            currency.format(activeSum),
            AppTheme.accentPurple,
          ),
          const Divider(height: 18),
          _breakdownRow(
            'Pesanan Mendatang (Booked)',
            '${bookedRentals.length} Transaksi',
            currency.format(bookedSum),
            AppTheme.primary,
          ),
          const Divider(height: 18),
          _breakdownRow(
            'Selesai & Lunas (Completed)',
            '${completedRentals.length} Transaksi',
            currency.format(completedSum),
            AppTheme.success,
          ),
        ],
      ),
    );
  }

  Widget _buildFleetUtilizationCard(
    int totalVehicles,
    int countTersedia,
    int countDisewa,
    int countBooking,
    int countPerawatan,
  ) {
    final pctDisewa = ((countDisewa + countBooking) / totalVehicles * 100).toInt();

    return Container(
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
              const Row(
                children: [
                  Icon(Icons.speed_rounded, size: 18, color: AppTheme.warning),
                  SizedBox(width: 8),
                  Text(
                    'Tingkat Utilisasi Armada',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('$pctDisewa% Aktif', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(flex: countDisewa.clamp(1, 999), child: Container(color: AppTheme.accentPurple)),
                  Expanded(flex: countBooking.clamp(1, 999), child: Container(color: AppTheme.primary)),
                  Expanded(flex: countTersedia.clamp(1, 999), child: Container(color: AppTheme.success)),
                  Expanded(flex: countPerawatan.clamp(1, 999), child: Container(color: AppTheme.warning)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _utilizationLegendRow('Sedang Disewa Pelanggan', '$countDisewa Unit', AppTheme.accentPurple),
          const SizedBox(height: 8),
          _utilizationLegendRow('Booking Terjadwal', '$countBooking Unit', AppTheme.primary),
          const SizedBox(height: 8),
          _utilizationLegendRow('Tersedia di Garasi', '$countTersedia Unit', AppTheme.success),
          const SizedBox(height: 8),
          _utilizationLegendRow('Perawatan / Bengkel', '$countPerawatan Unit', AppTheme.warning),
        ],
      ),
    );
  }

  Widget _breakdownRow(String title, String subtitle, String amount, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            ],
          ),
        ),
        Text(
          amount,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _utilizationLegendRow(String title, String count, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
        Text(count, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
      ],
    );
  }

  Widget _metricCard(String title, String val, String desc, Color color, IconData icon, {bool isMobile = false}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
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
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 15, color: color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                val,
                style: TextStyle(fontSize: isMobile ? 16 : 20, fontWeight: FontWeight.w800, color: color),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              style: const TextStyle(fontSize: 10, color: AppTheme.textDim),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
