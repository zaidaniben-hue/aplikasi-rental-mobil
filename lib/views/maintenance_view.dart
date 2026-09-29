import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class MaintenanceView extends StatefulWidget {
  const MaintenanceView({super.key});

  @override
  State<MaintenanceView> createState() => _MaintenanceViewState();
}

class _MaintenanceViewState extends State<MaintenanceView> {
  HealthLevel? _filterHealth; // null for all, or filter by level

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    final redVehicles = state.vehicles.where((v) => state.getHealthForVehicle(v.id).overallHealth == HealthLevel.merah).toList();
    final yellowVehicles = state.vehicles.where((v) => state.getHealthForVehicle(v.id).overallHealth == HealthLevel.kuning).toList();
    final greenVehicles = state.vehicles.where((v) => state.getHealthForVehicle(v.id).overallHealth == HealthLevel.hijau).toList();

    final displayedVehicles = state.vehicles.where((v) {
      if (_filterHealth == null) return true;
      return state.getHealthForVehicle(v.id).overallHealth == _filterHealth;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monitoring & Perawatan Armada',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pencegahan kerusakan, ambang batas odometer otomatis, dan pencatatan bengkel berkala',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.warning,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.build_circle_rounded, size: 18),
                  label: const Text('Catat Masuk Bengkel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  onPressed: () => _showLogbookEntryDialog(context, state),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Top KPI Summary Cards (Filterable with 1-click)
            Row(
              children: [
                _summaryCard(
                  title: 'Jatuh Tempo (Merah)',
                  count: redVehicles.length.toString(),
                  desc: 'Batas terlewati • Auto-Lock sewa',
                  color: AppTheme.danger,
                  icon: Icons.cancel_rounded,
                  isSelected: _filterHealth == HealthLevel.merah,
                  onTap: () {
                    setState(() {
                      _filterHealth = _filterHealth == HealthLevel.merah ? null : HealthLevel.merah;
                    });
                  },
                ),
                const SizedBox(width: 12),
                _summaryCard(
                  title: 'Siaga Servis (Kuning)',
                  count: yellowVehicles.length.toString(),
                  desc: 'Mendekati limit (<= 500 km / 7 hari)',
                  color: AppTheme.warning,
                  icon: Icons.warning_rounded,
                  isSelected: _filterHealth == HealthLevel.kuning,
                  onTap: () {
                    setState(() {
                      _filterHealth = _filterHealth == HealthLevel.kuning ? null : HealthLevel.kuning;
                    });
                  },
                ),
                const SizedBox(width: 12),
                _summaryCard(
                  title: 'Kondisi Prima (Hijau)',
                  count: greenVehicles.length.toString(),
                  desc: 'Layak jalan & aman disewakan',
                  color: AppTheme.success,
                  icon: Icons.check_circle_rounded,
                  isSelected: _filterHealth == HealthLevel.hijau,
                  onTap: () {
                    setState(() {
                      _filterHealth = _filterHealth == HealthLevel.hijau ? null : HealthLevel.hijau;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Fleet Health Cards List
            Expanded(
              child: displayedVehicles.isEmpty
                  ? Center(
                      child: Text(
                        'Tidak ada armada dengan filter ini.',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    )
                  : ListView.separated(
                      itemCount: displayedVehicles.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, idx) {
                        final vehicle = displayedVehicles[idx];
                        final health = state.getHealthForVehicle(vehicle.id);
                        final rules = state.maintenanceRules.where((r) => r.vehicleId == vehicle.id).toList();

                        Color statusColor;
                        switch (health.overallHealth) {
                          case HealthLevel.merah:
                            statusColor = AppTheme.danger;
                            break;
                          case HealthLevel.kuning:
                            statusColor = AppTheme.warning;
                            break;
                          case HealthLevel.hijau:
                            statusColor = AppTheme.success;
                            break;
                        }

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: health.overallHealth != HealthLevel.hijau
                                  ? statusColor.withValues(alpha: 0.45)
                                  : AppTheme.border,
                              width: health.overallHealth != HealthLevel.hijau ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Card Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      // Plate Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.surfaceInput,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppTheme.border),
                                        ),
                                        child: Text(
                                          vehicle.plateNumber,
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, fontFamily: 'monospace', color: AppTheme.textPrimary),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '${vehicle.brand} ${vehicle.model} (${vehicle.yearMade})',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                      ),
                                      const SizedBox(width: 10),
                                      // Health Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              health.overallHealth == HealthLevel.merah
                                                  ? Icons.cancel_rounded
                                                  : health.overallHealth == HealthLevel.kuning
                                                      ? Icons.warning_rounded
                                                      : Icons.check_circle_rounded,
                                              size: 13,
                                              color: statusColor,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              health.overallHealth.label,
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        'Odometer: ${NumberFormat('#,###').format(vehicle.odometerCurrent)} km',
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'monospace', fontSize: 12, color: AppTheme.textSecondary),
                                      ),
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Color(vehicle.status.colorValue).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          vehicle.status.label,
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(vehicle.status.colorValue)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Divider(height: 20),

                              // Maintenance Rules Grid
                              if (rules.isEmpty)
                                const Text('Belum ada jadwal servis berkala yang didaftarkan untuk unit ini.', style: TextStyle(fontSize: 12, color: AppTheme.textDim))
                              else
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 8,
                                  children: rules.map((r) {
                                    int? kmRemaining;
                                    int? daysRemaining;

                                    if (r.intervalKm != null) {
                                      kmRemaining = (r.lastServiceKm + r.intervalKm!) - vehicle.odometerCurrent;
                                    }
                                    if (r.intervalDays != null) {
                                      final nextDate = r.lastServiceDate.add(Duration(days: r.intervalDays!));
                                      daysRemaining = nextDate.difference(DateTime.now()).inDays;
                                    }

                                    final isRed = (kmRemaining != null && kmRemaining <= 0) || (daysRemaining != null && daysRemaining <= 0);
                                    final isYellow = (kmRemaining != null && kmRemaining <= 500) || (daysRemaining != null && daysRemaining <= 7);

                                    Color ruleColor = isRed
                                        ? AppTheme.danger
                                        : isYellow
                                            ? AppTheme.warning
                                            : AppTheme.border;

                                    return Container(
                                      width: 270,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isRed
                                            ? AppTheme.danger.withValues(alpha: 0.08)
                                            : isYellow
                                                ? AppTheme.warning.withValues(alpha: 0.08)
                                                : AppTheme.surfaceInput,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isRed || isYellow ? ruleColor.withValues(alpha: 0.4) : AppTheme.border,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  r.serviceType,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textPrimary),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isRed)
                                                const Text('LEWAT!', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold, fontSize: 10))
                                              else if (isYellow)
                                                const Text('SIAGA', style: TextStyle(color: AppTheme.warning, fontWeight: FontWeight.bold, fontSize: 10)),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          if (r.intervalKm != null)
                                            Text(
                                              'Tiap ${NumberFormat('#,###').format(r.intervalKm)} km (Sisa: ${kmRemaining != null && kmRemaining < 0 ? 'Lewat ${kmRemaining.abs()} km' : '${kmRemaining ?? 0} km'})',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isRed ? const Color(0xFFFCA5A5) : isYellow ? const Color(0xFFFDE68A) : AppTheme.textMuted,
                                              ),
                                            ),
                                          if (r.intervalDays != null)
                                            Text(
                                              'Tiap ${r.intervalDays} hari (Sisa: ${daysRemaining != null && daysRemaining < 0 ? 'Lewat ${daysRemaining.abs()} hari' : '$daysRemaining hari'})',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isRed ? const Color(0xFFFCA5A5) : isYellow ? const Color(0xFFFDE68A) : AppTheme.textMuted,
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),

                              // Quick Action: Complete service
                              if (health.overallHealth == HealthLevel.merah || vehicle.status == VehicleStatus.perawatan) ...[
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.success,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                                      label: const Text('Servis Telah Selesai (Kembalikan ke TERSEDIA)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      onPressed: () {
                                        state.completeMaintenance(
                                          vehicleId: vehicle.id,
                                          serviceType: rules.isNotEmpty ? rules.first.serviceType : 'Servis Berkala',
                                          completedOdometer: vehicle.odometerCurrent,
                                          workshopName: 'Bengkel Rekanan Resmi',
                                          cost: 750000,
                                        );
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            backgroundColor: AppTheme.success,
                                            content: Text('Unit ${vehicle.plateNumber} telah diservis dan kembali berstatus TERSEDIA!'),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
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

  Widget _summaryCard({
    required String title,
    required String count,
    required String desc,
    required Color color,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppTheme.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? color : AppTheme.textPrimary)),
                        Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(desc, style: const TextStyle(fontSize: 11, color: AppTheme.textDim)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogbookEntryDialog(BuildContext context, AppState state) {
    Vehicle? selectedVehicle = state.vehicles.isNotEmpty ? state.vehicles.first : null;
    final serviceTypeController = TextEditingController(text: 'Ganti Oli & Filter Mesin');
    final workshopController = TextEditingController(text: 'Bengkel Resmi Auto2000');
    final costController = TextEditingController(text: '850000');
    final odoController = TextEditingController(text: (selectedVehicle?.odometerCurrent ?? 0).toString());

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.border)),
          title: const Row(
            children: [
              Icon(Icons.build_circle_rounded, color: AppTheme.warning),
              SizedBox(width: 10),
              Text('Entri Catatan Servis Bengkel', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Vehicle>(
                    initialValue: selectedVehicle,
                    dropdownColor: AppTheme.surfaceCard,
                    decoration: const InputDecoration(labelText: 'Pilih Kendaraan'),
                    items: state.vehicles.map((v) => DropdownMenuItem(value: v, child: Text('${v.plateNumber} - ${v.brand} ${v.model}'))).toList(),
                    onChanged: (val) {
                      setDlgState(() {
                        selectedVehicle = val;
                        odoController.text = (val?.odometerCurrent ?? 0).toString();
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: serviceTypeController, decoration: const InputDecoration(labelText: 'Jenis Pekerjaan / Servis')),
                  const SizedBox(height: 10),
                  TextField(controller: workshopController, decoration: const InputDecoration(labelText: 'Nama Bengkel / Mekanik')),
                  const SizedBox(height: 10),
                  TextField(controller: odoController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Odometer saat Servis (km)')),
                  const SizedBox(height: 10),
                  TextField(controller: costController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Biaya Perbaikan (Rp)')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: AppTheme.textMuted))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning, foregroundColor: Colors.black),
              onPressed: () {
                if (selectedVehicle == null) return;
                state.completeMaintenance(
                  vehicleId: selectedVehicle!.id,
                  serviceType: serviceTypeController.text.trim(),
                  completedOdometer: int.tryParse(odoController.text) ?? selectedVehicle!.odometerCurrent,
                  workshopName: workshopController.text.trim(),
                  cost: double.tryParse(costController.text) ?? 0.0,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(backgroundColor: AppTheme.success, content: Text('Riwayat servis berhasil dicatat. Status unit kembali TERSEDIA.')),
                );
              },
              child: const Text('Simpan & Selesaikan Servis', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
