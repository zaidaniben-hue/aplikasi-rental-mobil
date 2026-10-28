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
  final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

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

    final isMobile = MediaQuery.of(context).size.width < 800;

    final summaryCards = [
      _summaryCard(
        title: 'Jatuh Tempo (Merah)',
        count: redVehicles.length.toString(),
        desc: 'Batas terlewati • Auto-Lock sewa',
        color: AppTheme.danger,
        icon: Icons.cancel_rounded,
        isSelected: _filterHealth == HealthLevel.merah,
        isMobile: isMobile,
        onTap: () {
          setState(() {
            _filterHealth = _filterHealth == HealthLevel.merah ? null : HealthLevel.merah;
          });
        },
      ),
      _summaryCard(
        title: 'Siaga Servis (Kuning)',
        count: yellowVehicles.length.toString(),
        desc: 'Mendekati limit (<= 500 km / 7 hari)',
        color: AppTheme.warning,
        icon: Icons.warning_rounded,
        isSelected: _filterHealth == HealthLevel.kuning,
        isMobile: isMobile,
        onTap: () {
          setState(() {
            _filterHealth = _filterHealth == HealthLevel.kuning ? null : HealthLevel.kuning;
          });
        },
      ),
      _summaryCard(
        title: 'Kondisi Prima (Hijau)',
        count: greenVehicles.length.toString(),
        desc: 'Layak jalan & aman disewakan',
        color: AppTheme.success,
        icon: Icons.check_circle_rounded,
        isSelected: _filterHealth == HealthLevel.hijau,
        isMobile: isMobile,
        onTap: () {
          setState(() {
            _filterHealth = _filterHealth == HealthLevel.hijau ? null : HealthLevel.hijau;
          });
        },
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            if (isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Monitoring & Perawatan Armada',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    state.currentRole == UserRole.frontDesk
                        ? 'Pengawasan ambang batas servis (Mode Kasir: Hanya-baca)'
                        : 'Pencegahan kerusakan & jadwal servis bengkel armada',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 12),
                  if (state.currentRole != UserRole.frontDesk)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
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
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceInput,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shield_outlined, size: 15, color: AppTheme.textMuted),
                          SizedBox(width: 8),
                          Text(
                            'Mode Kasir: Penginputan servis hanya oleh Mekanik',
                            style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                ],
              )
            else
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
                        state.currentRole == UserRole.frontDesk
                            ? 'Pencegahan kerusakan dan status unit (Mode Kasir: Hanya-baca)'
                            : 'Pencegahan kerusakan, ambang batas odometer otomatis, dan pencatatan bengkel berkala',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  if (state.currentRole != UserRole.frontDesk)
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
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceInput,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_outlined, size: 15, color: AppTheme.textMuted),
                          SizedBox(width: 8),
                          Text(
                            'Mode Kasir: Hanya-Baca',
                            style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 16),

            // Top KPI Summary Cards
            if (isMobile)
              Column(
                children: [
                  summaryCards[0],
                  const SizedBox(height: 8),
                  summaryCards[1],
                  const SizedBox(height: 8),
                  summaryCards[2],
                ],
              )
            else
              Row(
                children: [
                  summaryCards[0],
                  const SizedBox(width: 12),
                  summaryCards[1],
                  const SizedBox(width: 12),
                  summaryCards[2],
                ],
              ),
            const SizedBox(height: 14),

            // AI Linear Regression Maintenance Budget Banner
            _buildAiLinearRegressionBanner(context, state, isMobile),
            const SizedBox(height: 14),

            // Fleet Health Cards List
            Expanded(
              child: displayedVehicles.isEmpty
                  ? const Center(
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
                              if (isMobile)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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
                                            const SizedBox(width: 8),
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
                                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Color(vehicle.status.colorValue).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            vehicle.status.label,
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(vehicle.status.colorValue)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${vehicle.brand} ${vehicle.model} (${vehicle.yearMade})',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Odometer: ${NumberFormat('#,###').format(vehicle.odometerCurrent)} km',
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'monospace', fontSize: 12, color: AppTheme.textSecondary),
                                    ),
                                  ],
                                )
                              else
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

                              // AI Linear Regression Estimator Chip/Card for this vehicle
                              _buildVehicleAiCostCard(context, state, vehicle),
                              const SizedBox(height: 12),

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
                                      width: isMobile ? double.infinity : 270,
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

                              // Quick Action: Complete service (Mechanic & Manager only)
                              if (health.overallHealth == HealthLevel.merah || vehicle.status == VehicleStatus.perawatan) ...[
                                const SizedBox(height: 12),
                                if (state.currentRole != UserRole.frontDesk)
                                  SizedBox(
                                    width: isMobile ? double.infinity : null,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.success,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.danger.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                                    ),
                                    child: const Text('Unit terkunci oleh sistem. Menunggu penanganan mekanik armada.', style: TextStyle(fontSize: 11, color: AppTheme.danger, fontWeight: FontWeight.w600)),
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
    bool isMobile = false,
  }) {
    final cardContent = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
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
    );

    if (isMobile) {
      return cardContent;
    }
    return Expanded(child: cardContent);
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
          content: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            width: double.infinity,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Vehicle>(
                    initialValue: selectedVehicle,
                    isExpanded: true,
                    dropdownColor: AppTheme.surfaceCard,
                    decoration: const InputDecoration(labelText: 'Pilih Kendaraan'),
                    items: state.vehicles
                        .map((v) => DropdownMenuItem(
                              value: v,
                              child: Text(
                                '${v.plateNumber} - ${v.brand} ${v.model}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
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

  // =========================================================================
  // MACHINE LEARNING 1: LINEAR REGRESSION (Biaya Servis & Anggaran Perawatan)
  // =========================================================================

  Widget _buildAiLinearRegressionBanner(BuildContext context, AppState state, bool isMobile) {
    double totalPredictedFleetCost = 0.0;
    for (var v in state.vehicles) {
      totalPredictedFleetCost += state.getPredictedMaintenanceCost(v);
    }
    final lin = state.mlService.linearRegression;
    final r2Percent = (lin.r2Score * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E3A8A).withValues(alpha: 0.35),
            const Color(0xFF0F172A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.auto_awesome, color: Color(0xFF60A5FA), size: 16),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'AI Linear Regression Engine',
                      style: TextStyle(color: Color(0xFF93C5FD), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('R²: $r2Percent%', style: const TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Estimasi Alokasi Dana Servis Armada: ${currency.format(totalPredictedFleetCost)}',
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Dihitung otomatis berbasis regresi OLS (Odometer + Usia Unit)',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF93C5FD),
                      side: const BorderSide(color: Color(0xFF3B82F6)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.calculate_outlined, size: 14),
                    label: const Text('Kalkulator Prediksi AI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () => _showLinearRegressionEstimatorDialog(context, state),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Color(0xFF60A5FA), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'AI Predictive Cost Engine (Linear Regression)',
                            style: TextStyle(color: Color(0xFF93C5FD), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
                            ),
                            child: Text('Model Fit R²: $r2Percent%', style: const TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total Proyeksi Anggaran Perawatan Seluruh Armada: ${currency.format(totalPredictedFleetCost)}',
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Formula Regresi: Estimasi Biaya = (w₁ × Odometer KM) + (w₂ × Usia Mobil) + Bias OLS',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontFamily: 'monospace'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.calculate_outlined, size: 15),
                  label: const Text('Kalkulator Prediksi AI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () => _showLinearRegressionEstimatorDialog(context, state),
                ),
              ],
            ),
    );
  }

  Widget _buildVehicleAiCostCard(BuildContext context, AppState state, Vehicle vehicle) {
    final predictedCost = state.getPredictedMaintenanceCost(vehicle);
    final age = (DateTime.now().year - vehicle.yearMade).clamp(1, 25);
    final lin = state.mlService.linearRegression;
    final wKm = lin.weights.isNotEmpty ? lin.weights[0] : 35.0;
    final wAge = lin.weights.length > 1 ? lin.weights[1] : 200000.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF60A5FA)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Prediksi Servis (Linear Regression):',
                      style: TextStyle(fontSize: 11, color: Color(0xFF93C5FD), fontWeight: FontWeight.w600),
                    ),
                    Text(
                      currency.format(predictedCost),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
                Text(
                  'Bobot Fitur: (${NumberFormat('#,###').format(vehicle.odometerCurrent)} km × ${wKm.toStringAsFixed(1)}) + ($age thn × ${currency.format(wAge)})',
                  style: const TextStyle(fontSize: 10, color: AppTheme.textDim, fontFamily: 'monospace'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () => _showLinearRegressionEstimatorDialog(context, state, preselectedVehicle: vehicle),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('Simulasi', style: TextStyle(fontSize: 11, color: Color(0xFF60A5FA), fontWeight: FontWeight.bold)),
                  Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF60A5FA)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLinearRegressionEstimatorDialog(BuildContext context, AppState state, {Vehicle? preselectedVehicle}) {
    Vehicle? selected = preselectedVehicle ?? (state.vehicles.isNotEmpty ? state.vehicles.first : null);
    double simKm = selected?.odometerCurrent.toDouble() ?? 45000.0;
    double simAge = selected != null ? (DateTime.now().year - selected.yearMade).toDouble().clamp(1.0, 20.0) : 3.0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final lin = state.mlService.linearRegression;
          final estimatedCost = state.mlService.predictMaintenanceCost(odometerKm: simKm, vehicleAgeYears: simAge);
          final r2 = (lin.r2Score * 100).toStringAsFixed(1);

          return Dialog(
            backgroundColor: AppTheme.surfaceCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.border)),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              padding: const EdgeInsets.all(20),
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
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.show_chart_rounded, color: Color(0xFF60A5FA), size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Linear Regression Estimator',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                        IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted)),
                      ],
                    ),
                    const Divider(height: 20),

                    // Model Formula Box
                    Container(
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
                              const Text('Formula Regresi Linier OLS:', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                              Text('Akurasi R²: $r2%', style: const TextStyle(fontSize: 11, color: AppTheme.success, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lin.getFormulaString(),
                            style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF93C5FD), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Vehicle Quick Select
                    const Text('Pilih Unit Armada (Opsional):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<Vehicle>(
                      initialValue: selected,
                      isExpanded: true,
                      dropdownColor: AppTheme.surfaceCard,
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                      items: state.vehicles.map((v) {
                        return DropdownMenuItem(
                          value: v,
                          child: Text(
                            '${v.plateNumber} - ${v.brand} ${v.model} (${v.odometerCurrent} km)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDlgState(() {
                            selected = val;
                            simKm = val.odometerCurrent.toDouble();
                            simAge = (DateTime.now().year - val.yearMade).toDouble().clamp(1.0, 20.0);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Sliders
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Simulasi Jarak Tempuh (KM):', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        Text('${NumberFormat('#,###').format(simKm.toInt())} km', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'monospace')),
                      ],
                    ),
                    Slider(
                      value: simKm,
                      min: 0,
                      max: 200000,
                      divisions: 200,
                      activeColor: const Color(0xFF3B82F6),
                      onChanged: (val) => setDlgState(() => simKm = val),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Usia Kendaraan (Tahun):', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        Text('${simAge.toStringAsFixed(1)} Tahun', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      ],
                    ),
                    Slider(
                      value: simAge,
                      min: 1,
                      max: 15,
                      divisions: 28,
                      activeColor: const Color(0xFF3B82F6),
                      onChanged: (val) => setDlgState(() => simAge = val),
                    ),
                    const SizedBox(height: 14),

                    // Result Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [const Color(0xFF1E3A8A).withValues(alpha: 0.3), const Color(0xFF0F172A)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Hasil Proyeksi Biaya Servis:', style: TextStyle(fontSize: 11, color: Color(0xFF93C5FD))),
                              SizedBox(height: 2),
                              Text('Rekomendasi Plafon Anggaran', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                            ],
                          ),
                          Text(
                            currency.format(estimatedCost),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF60A5FA)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Tutup Kalkulator'),
                      ),
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
}
