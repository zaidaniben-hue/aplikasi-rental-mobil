import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class GanttTimelineView extends StatelessWidget {
  final AppState state;
  final Function(Vehicle)? onVehicleSelected;

  const GanttTimelineView({
    super.key,
    required this.state,
    this.onVehicleSelected,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List.generate(14, (i) => today.add(Duration(days: i)));
    final vehicles = state.filteredVehicles;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Legend
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Matriks Ketersediaan Armada (14 Hari Kedepan)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Visualisasi anti-bentrok jadwal & monitoring utilisasi unit',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
              Wrap(
                spacing: 12,
                children: [
                  _legendBadge(AppTheme.success, 'Tersedia'),
                  _legendBadge(AppTheme.primary, 'Booking'),
                  _legendBadge(AppTheme.accentPurple, 'Disewa'),
                  _legendBadge(AppTheme.warning, 'Perawatan'),
                  _legendBadge(AppTheme.danger, 'Tidak Aktif'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Timeline Table Grid
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 220 + (days.length * 62.0),
                child: Column(
                  children: [
                    // Date Headers
                    Row(
                      children: [
                        Container(
                          width: 220,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          alignment: Alignment.centerLeft,
                          decoration: const BoxDecoration(
                            color: AppTheme.surfaceInput,
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(8)),
                          ),
                          child: const Text('Armada / Plat No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textMuted)),
                        ),
                        ...days.map((d) {
                          final isToday = d.day == now.day && d.month == now.month && d.year == now.year;
                          return Container(
                            width: 62,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isToday ? AppTheme.primary.withValues(alpha: 0.15) : AppTheme.surfaceInput,
                              border: const Border(left: BorderSide(color: AppTheme.border)),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  DateFormat('E').format(d),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isToday ? AppTheme.primary : AppTheme.textMuted,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  DateFormat('dd/MM').format(d),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                    color: isToday ? AppTheme.primary : AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                    const Divider(height: 1, thickness: 1, color: AppTheme.border),

                    // Vehicle Rows
                    Expanded(
                      child: ListView.separated(
                        itemCount: vehicles.length,
                        separatorBuilder: (_, _) => const Divider(height: 1, thickness: 1, color: AppTheme.border),
                        itemBuilder: (context, idx) {
                          final v = vehicles[idx];
                          return InkWell(
                            onTap: () => onVehicleSelected?.call(v),
                            child: SizedBox(
                              height: 48,
                              child: Row(
                                children: [
                                  // Vehicle Label
                                  Container(
                                    width: 220,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.surfaceInput,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: AppTheme.border),
                                          ),
                                          child: Text(
                                            v.plateNumber,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'monospace', color: AppTheme.textPrimary),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${v.brand} ${v.model}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Day Cells
                                  ...days.map((dayDate) {
                                    final cellStatus = _getStatusForVehicleOnDate(v, dayDate, state);
                                    return Container(
                                      width: 62,
                                      height: 48,
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        border: Border(left: BorderSide(color: AppTheme.border)),
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: cellStatus.color.withValues(alpha: 0.8),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          cellStatus.shortLabel,
                                          style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _DayCellStatus _getStatusForVehicleOnDate(Vehicle v, DateTime date, AppState state) {
    if (v.status == VehicleStatus.tidakAktif) {
      return _DayCellStatus(AppTheme.danger, 'X');
    }
    if (v.status == VehicleStatus.perawatan) {
      return _DayCellStatus(AppTheme.warning, 'SRV');
    }

    final dateStart = DateTime(date.year, date.month, date.day, 0, 0);
    final dateEnd = DateTime(date.year, date.month, date.day, 23, 59);

    for (final r in state.rentals) {
      if (r.vehicleId != v.id) continue;
      if (r.rentalStatus == 'CANCELLED' || r.rentalStatus == 'COMPLETED') continue;

      if (r.startTime.isBefore(dateEnd) && r.plannedEndTime.isAfter(dateStart)) {
        if (r.rentalStatus == 'ACTIVE') {
          return _DayCellStatus(AppTheme.accentPurple, 'SEWA');
        } else if (r.rentalStatus == 'BOOKED') {
          return _DayCellStatus(AppTheme.primary, 'BOOK');
        }
      }
    }

    return _DayCellStatus(AppTheme.success, 'ADA');
  }

  Widget _legendBadge(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }
}

class _DayCellStatus {
  final Color color;
  final String shortLabel;
  _DayCellStatus(this.color, this.shortLabel);
}
