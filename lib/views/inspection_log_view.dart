import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class InspectionLogView extends StatefulWidget {
  const InspectionLogView({super.key});

  @override
  State<InspectionLogView> createState() => _InspectionLogViewState();
}

class _InspectionLogViewState extends State<InspectionLogView> {
  String _filterType = 'ALL'; // 'ALL', 'WITH_DEFECTS', 'CHECK_IN', 'CHECK_OUT'
  String _searchQuery = '';
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isMobile = MediaQuery.of(context).size.width < 800;

    // Filtered inspection items
    final filtered = state.inspections.where((insp) {
      if (_filterType == 'WITH_DEFECTS' && insp.bodyDefects.isEmpty) {
        return false;
      }
      if (_filterType == 'CHECK_IN' && insp.type != 'CHECK_IN') {
        return false;
      }
      if (_filterType == 'CHECK_OUT' && insp.type != 'CHECK_OUT') {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final vehicle = state.vehicles.where((v) => v.id == insp.vehicleId).firstOrNull;
        final matchesPlate = vehicle?.plateNumber.toLowerCase().contains(q) ?? false;
        final matchesBrand = vehicle?.displayName.toLowerCase().contains(q) ?? false;
        final matchesNotes = insp.notes.toLowerCase().contains(q);
        if (!matchesPlate && !matchesBrand && !matchesNotes) return false;
      }

      return true;
    }).toList();

    final totalDefects = state.inspections.fold(0, (sum, i) => sum + i.bodyDefects.length);
    final countWithDefects = state.inspections.where((i) => i.bodyDefects.isNotEmpty).length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Log Kerusakan Fisik & Inspeksi Bodi',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pusat pemantauan cacat bodi (gores, penyok, pecah) dari serah terima unit',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.handyman_rounded, color: AppTheme.primary, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '$totalDefects Cacat Terdeteksi',
                            style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Summary Cards
            Row(
              children: [
                _metricCard(
                  'Total Inspeksi',
                  state.inspections.length.toString(),
                  'Serah terima unit',
                  AppTheme.primary,
                  Icons.assignment_turned_in_rounded,
                  isMobile: isMobile,
                ),
                const SizedBox(width: 10),
                _metricCard(
                  'Unit Berkeluhan',
                  countWithDefects.toString(),
                  'Ada cacat bodi',
                  AppTheme.warning,
                  Icons.warning_amber_rounded,
                  isMobile: isMobile,
                ),
                const SizedBox(width: 10),
                _metricCard(
                  'Total Cacat Bodi',
                  totalDefects.toString(),
                  'Goresan / penyok',
                  AppTheme.danger,
                  Icons.car_crash_rounded,
                  isMobile: isMobile,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // SVM Roadworthiness Intelligence Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.35)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.shield_outlined, size: 16, color: Color(0xFFA78BFA)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI Safety Hyperplane (Support Vector Machine): Mengklasifikasi kelaikan unit secara otomatis berdasarkan akumulasi titik cacat & kilometer.',
                      style: TextStyle(fontSize: 11, color: Color(0xFFC4B5FD)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Search & Filter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 18, color: AppTheme.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Cari plat nomor, mobil, atau catatan kerusakan...',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Filter Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('Semua Inspeksi', 'ALL', state.inspections.length),
                  const SizedBox(width: 8),
                  _filterChip('Ada Cacat Bodi Saja', 'WITH_DEFECTS', countWithDefects, isAlert: true),
                  const SizedBox(width: 8),
                  _filterChip('Saat Check-In (Kembali)', 'CHECK_IN', state.inspections.where((i) => i.type == 'CHECK_IN').length),
                  const SizedBox(width: 8),
                  _filterChip('Saat Check-Out (Keluar)', 'CHECK_OUT', state.inspections.where((i) => i.type == 'CHECK_OUT').length),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // List of Inspection Records
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline, size: 48, color: AppTheme.success.withValues(alpha: 0.6)),
                          const SizedBox(height: 10),
                          const Text(
                            'Tidak ada log inspeksi yang sesuai filter.',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, idx) {
                        final insp = filtered[idx];
                        final vehicle = state.vehicles.where((v) => v.id == insp.vehicleId).firstOrNull;
                        final isCheckIn = insp.type == 'CHECK_IN';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: insp.bodyDefects.isNotEmpty
                                  ? AppTheme.warning.withValues(alpha: 0.5)
                                  : AppTheme.border,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isCheckIn
                                              ? AppTheme.primary.withValues(alpha: 0.2)
                                              : AppTheme.accentPurple.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: isCheckIn ? AppTheme.primary : AppTheme.accentPurple,
                                          ),
                                        ),
                                        child: Text(
                                          isCheckIn ? 'KEMBALI (CHECK-IN)' : 'SERAH TERIMA (CHECK-OUT)',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: isCheckIn ? AppTheme.primary : AppTheme.accentPurple,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        vehicle?.plateNumber ?? 'PLAT TIDAK DIKETAHUI',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace',
                                          fontSize: 13,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      if (vehicle != null) ...[
                                        Builder(builder: (context) {
                                          final svm = state.getVehicleSafetyEvaluation(vehicle);
                                          final color = svm.isPositive ? AppTheme.success : AppTheme.danger;
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: color.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: color.withValues(alpha: 0.3)),
                                            ),
                                            child: Text(
                                              'SVM: ${svm.isPositive ? "PRIMA" : "KRITIS"}',
                                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
                                            ),
                                          );
                                        }),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    dateFormat.format(insp.createdAt),
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${vehicle?.brand ?? ''} ${vehicle?.model ?? ''} • Odometer: ${NumberFormat('#,###').format(insp.odometer)} km • BBM: ${insp.fuelLevel}/8',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                              if (insp.notes.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Catatan: ${insp.notes}',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textDim, fontStyle: FontStyle.italic),
                                ),
                              ],
                              if (insp.bodyDefects.isNotEmpty) ...[
                                const Divider(height: 16),
                                const Row(
                                  children: [
                                    Icon(Icons.car_crash_rounded, size: 14, color: AppTheme.warning),
                                    SizedBox(width: 6),
                                    Text(
                                      'Titik Cacat Fisik Yang Perlu Diperbaiki:',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.warning),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: insp.bodyDefects.map((def) {
                                    Color badgeColor;
                                    switch (def.severity) {
                                      case 'high':
                                        badgeColor = AppTheme.danger;
                                        break;
                                      case 'medium':
                                        badgeColor = AppTheme.warning;
                                        break;
                                      default:
                                        badgeColor = AppTheme.success;
                                    }

                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: badgeColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                                      ),
                                      child: Text(
                                        '[Sisi ${def.view.toUpperCase()}] ${def.type.toUpperCase()}: ${def.notes.isNotEmpty ? def.notes : 'Tingkat ${def.severity}'}',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: badgeColor),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String title, String val, int count, {bool isAlert = false}) {
    final isSelected = _filterType == val;
    final color = isAlert ? AppTheme.warning : AppTheme.primary;

    return InkWell(
      onTap: () => setState(() => _filterType = val),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : AppTheme.surfaceInput,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppTheme.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? color : AppTheme.border,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppTheme.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCard(String title, String val, String desc, Color color, IconData icon, {bool isMobile = false}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(isMobile ? 10 : 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(10),
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
                Icon(icon, size: 16, color: color),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              val,
              style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.w800, color: color),
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
