import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/quick_action_dialogs.dart';

class FleetView extends StatelessWidget {
  const FleetView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final selected = state.selectedVehicle ?? (state.filteredVehicles.isNotEmpty ? state.filteredVehicles.first : (state.vehicles.isNotEmpty ? state.vehicles.first : null));

    final countTersedia = state.vehicles.where((v) => v.status == VehicleStatus.tersedia).length;
    final countDisewa = state.vehicles.where((v) => v.status == VehicleStatus.disewa).length;
    final countBooking = state.vehicles.where((v) => v.status == VehicleStatus.booking).length;
    final countPerawatan = state.vehicles.where((v) => v.status == VehicleStatus.perawatan).length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Pane: Filters & Data Grid (Master)
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Action Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Katalog & Inventaris Armada',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${state.filteredVehicles.length} dari ${state.vehicles.length} unit kendaraan siap beroperasi',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Tambah Unit Baru', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        onPressed: () => _showAddVehicleDialog(context, state),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Search Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: TextField(
                                onChanged: (q) => state.setVehicleSearch(q),
                                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Cari nomor plat, merek, atau model (Ctrl+F)...',
                                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppTheme.textMuted),
                                  suffixIcon: state.vehicleSearchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear_rounded, size: 16, color: AppTheme.textMuted),
                                          onPressed: () => state.setVehicleSearch(''),
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                            Container(width: 1, height: 24, color: AppTheme.border),
                            const SizedBox(width: 10),
                            // Filter Transmisi
                            Expanded(
                              flex: 2,
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String?>(
                                  value: state.transmissionFilter,
                                  dropdownColor: AppTheme.surfaceCard,
                                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                                  hint: const Text('Semua Transmisi', style: TextStyle(color: AppTheme.textDim, fontSize: 12)),
                                  icon: const Icon(Icons.arrow_drop_down, color: AppTheme.textMuted, size: 18),
                                  isExpanded: true,
                                  items: const [
                                    DropdownMenuItem(value: null, child: Text('Semua Transmisi')),
                                    DropdownMenuItem(value: 'OTOMATIS', child: Text('Otomatis (AT)')),
                                    DropdownMenuItem(value: 'MANUAL', child: Text('Manual (MT)')),
                                  ],
                                  onChanged: (val) => state.setTransmissionFilter(val),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Filter Kategori
                            Expanded(
                              flex: 2,
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String?>(
                                  value: state.categoryFilter,
                                  dropdownColor: AppTheme.surfaceCard,
                                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                                  hint: const Text('Semua Tipe', style: TextStyle(color: AppTheme.textDim, fontSize: 12)),
                                  icon: const Icon(Icons.arrow_drop_down, color: AppTheme.textMuted, size: 18),
                                  isExpanded: true,
                                  items: const [
                                    DropdownMenuItem(value: null, child: Text('Semua Kategori')),
                                    DropdownMenuItem(value: 'CITY_CAR', child: Text('City Car')),
                                    DropdownMenuItem(value: 'MPV', child: Text('MPV')),
                                    DropdownMenuItem(value: 'SUV', child: Text('SUV')),
                                    DropdownMenuItem(value: 'MINIBUS', child: Text('Minibus')),
                                  ],
                                  onChanged: (val) => state.setCategoryFilter(val),
                                ),
                              ),
                            ),
                            if (state.transmissionFilter != null || state.categoryFilter != null || state.vehicleSearchQuery.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.refresh_rounded, size: 18, color: AppTheme.textMuted),
                                tooltip: 'Reset Filter',
                                onPressed: () => state.clearFilters(),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Quick Status Filter Pills (Simple and uncluttered!)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _filterPill(
                                label: 'Semua Status',
                                count: state.vehicles.length,
                                isSelected: state.statusFilter == null,
                                color: AppTheme.primary,
                                onTap: () => state.setStatusFilter(null),
                              ),
                              const SizedBox(width: 8),
                              _filterPill(
                                label: 'Tersedia',
                                count: countTersedia,
                                isSelected: state.statusFilter == VehicleStatus.tersedia,
                                color: AppTheme.success,
                                onTap: () => state.setStatusFilter(VehicleStatus.tersedia),
                              ),
                              const SizedBox(width: 8),
                              _filterPill(
                                label: 'Sedang Disewa',
                                count: countDisewa,
                                isSelected: state.statusFilter == VehicleStatus.disewa,
                                color: AppTheme.accentPurple,
                                onTap: () => state.setStatusFilter(VehicleStatus.disewa),
                              ),
                              const SizedBox(width: 8),
                              _filterPill(
                                label: 'Booking',
                                count: countBooking,
                                isSelected: state.statusFilter == VehicleStatus.booking,
                                color: AppTheme.primary,
                                onTap: () => state.setStatusFilter(VehicleStatus.booking),
                              ),
                              const SizedBox(width: 8),
                              _filterPill(
                                label: 'Perawatan',
                                count: countPerawatan,
                                isSelected: state.statusFilter == VehicleStatus.perawatan,
                                color: AppTheme.warning,
                                onTap: () => state.setStatusFilter(VehicleStatus.perawatan),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Data Grid Table
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: state.filteredVehicles.isEmpty
                            ? const Center(
                                child: Text('Tidak ada kendaraan yang cocok dengan kriteria pencarian.', style: TextStyle(color: AppTheme.textMuted)),
                              )
                            : ListView.separated(
                                itemCount: state.filteredVehicles.length,
                                separatorBuilder: (_, _) => const Divider(height: 1),
                                itemBuilder: (context, idx) {
                                  final v = state.filteredVehicles[idx];
                                  final isSelected = selected?.id == v.id;
                                  final health = state.getHealthForVehicle(v.id);

                                  return InkWell(
                                    onTap: () => state.selectVehicle(v),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 120),
                                      color: isSelected ? AppTheme.primary.withValues(alpha: 0.12) : Colors.transparent,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      child: Row(
                                        children: [
                                          // Automotive Plate Badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppTheme.surfaceInput,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: isSelected ? AppTheme.primary : AppTheme.border,
                                                width: isSelected ? 1.5 : 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                _healthDot(health.overallHealth),
                                                const SizedBox(width: 6),
                                                Text(
                                                  v.plateNumber,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 12,
                                                    fontFamily: 'monospace',
                                                    color: AppTheme.textPrimary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 14),

                                          // Brand & Model
                                          Expanded(
                                            flex: 3,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${v.brand} ${v.model}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 13,
                                                    color: AppTheme.textPrimary,
                                                  ),
                                                ),
                                                Text(
                                                  '${v.category} • Tahun ${v.yearMade}',
                                                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Specs & Odo
                                          Expanded(
                                            flex: 2,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  v.transmission == 'OTOMATIS' ? 'Automatic (AT)' : 'Manual (MT)',
                                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                                ),
                                                Text(
                                                  '${NumberFormat('#,###').format(v.odometerCurrent)} km',
                                                  style: const TextStyle(fontSize: 11, color: AppTheme.textDim, fontFamily: 'monospace'),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Rate
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              '${currency.format(v.dailyRate)}/hr',
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                                            ),
                                          ),

                                          // Status Badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Color(v.status.colorValue).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: Color(v.status.colorValue).withValues(alpha: 0.4)),
                                            ),
                                            child: Text(
                                              v.status.label,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Color(v.status.colorValue),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right Pane: Detail View (Detail)
          Expanded(
            flex: 4,
            child: Container(
              height: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceCard,
                border: Border(left: BorderSide(color: AppTheme.border)),
              ),
              child: selected == null
                  ? const Center(
                      child: Text('Pilih unit kendaraan untuk melihat detail spesifikasi.', style: TextStyle(color: AppTheme.textMuted)),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header detail
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.surfaceInput,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppTheme.primary),
                                        ),
                                        child: Text(
                                          selected.plateNumber,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            fontFamily: 'monospace',
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${selected.brand} ${selected.model}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Color(selected.status.colorValue).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Color(selected.status.colorValue).withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  selected.status.label,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(selected.status.colorValue)),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),

                          // Health Radar Banner
                          Builder(builder: (context) {
                            final health = state.getHealthForVehicle(selected.id);
                            Color bannerColor;
                            String text;
                            IconData icon;
                            switch (health.overallHealth) {
                              case HealthLevel.merah:
                                bannerColor = AppTheme.danger;
                                text = 'KONDISI: JATUH TEMPO SERVIS (Unit Dikunci)';
                                icon = Icons.cancel_rounded;
                                break;
                              case HealthLevel.kuning:
                                bannerColor = AppTheme.warning;
                                text = 'KONDISI: SIAGA SERVIS (Mendekati Batas Odo/Waktu)';
                                icon = Icons.warning_rounded;
                                break;
                              case HealthLevel.hijau:
                                bannerColor = AppTheme.success;
                                text = 'KONDISI: PRIMA & LAYAK OPERASI';
                                icon = Icons.check_circle_rounded;
                                break;
                            }

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: bannerColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: bannerColor.withValues(alpha: 0.35)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(icon, size: 16, color: bannerColor),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          text,
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: bannerColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (health.alerts.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    ...health.alerts.map((a) => Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text(
                                            '• ${a.serviceType}: ${a.kmRemaining != null ? 'Sisa ${a.kmRemaining} km' : ''} ${a.daysRemaining != null ? 'Sisa ${a.daysRemaining} hari' : ''}',
                                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                          ),
                                        )),
                                  ],
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 18),

                          // Vehicle Specs Grid
                          const Text('Spesifikasi Fisik & Dokumen', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary)),
                          const SizedBox(height: 10),
                          _specTile('Tarif Sewa Harian', currency.format(selected.dailyRate), isHighlight: true),
                          _specTile('Odometer Saat Ini', '${NumberFormat('#,###').format(selected.odometerCurrent)} km'),
                          _specTile('Transmisi', selected.transmission == 'OTOMATIS' ? 'Otomatis (AT)' : 'Manual (MT)'),
                          _specTile('Kategori Kendaraan', selected.category),
                          _specTile('Jenis Bahan Bakar', selected.fuelType),
                          _specTile('Nomor Rangka (VIN)', selected.vin),
                          _specTile('Nomor Mesin', selected.engineNumber),

                          const Divider(height: 24),

                          // Maintenance Rules
                          const Text('Aturan Servis Terjadwal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary)),
                          const SizedBox(height: 8),
                          ...state.maintenanceRules.where((r) => r.vehicleId == selected.id).map((r) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceInput,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(r.serviceType, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textPrimary)),
                                  Text(
                                    '${r.intervalKm != null ? 'Tiap ${r.intervalKm} km' : ''} ${r.intervalDays != null ? 'Tiap ${r.intervalDays} hari' : ''}',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            );
                          }),

                          const SizedBox(height: 20),
                          // Action Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: selected.status == VehicleStatus.tersedia ? AppTheme.primary : AppTheme.surfaceElevated,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 18),
                              label: Text(
                                selected.status == VehicleStatus.tersedia ? 'Sewa Unit Ini' : 'Unit Sedang Tidak Tersedia (${selected.status.label})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              onPressed: selected.status != VehicleStatus.tersedia
                                  ? null
                                  : () => QuickActionDialogs.showNewBookingDialog(context, state, preselectedVehicle: selected),
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

  static Widget _filterPill({
    required String label,
    required int count,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : AppTheme.surfaceInput,
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
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? color : AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
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

  static Widget _healthDot(HealthLevel h) {
    Color c;
    switch (h) {
      case HealthLevel.merah:
        c = AppTheme.danger;
        break;
      case HealthLevel.kuning:
        c = AppTheme.warning;
        break;
      case HealthLevel.hijau:
        c = AppTheme.success;
        break;
    }
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    );
  }

  static Widget _specTile(String label, String value, {bool isHighlight = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isHighlight ? AppTheme.primary.withValues(alpha: 0.1) : AppTheme.surfaceInput,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isHighlight ? AppTheme.primary.withValues(alpha: 0.3) : AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isHighlight ? AppTheme.primary : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddVehicleDialog(BuildContext context, AppState state) {
    final plateController = TextEditingController();
    final brandController = TextEditingController(text: 'Toyota');
    final modelController = TextEditingController(text: 'Yaris Cross 1.5 S AT');
    final vinController = TextEditingController(text: 'MHFM4BA3NPK009988');
    final engineController = TextEditingController(text: '2NR-VE-112233');
    final yearController = TextEditingController(text: '2024');
    final rateController = TextEditingController(text: '500000');
    final odoController = TextEditingController(text: '5000');
    String transmission = 'OTOMATIS';
    String category = 'SUV';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.border)),
          title: const Row(
            children: [
              Icon(Icons.directions_car_rounded, color: AppTheme.primary),
              SizedBox(width: 10),
              Text('Tambah Unit Kendaraan Baru', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: plateController, decoration: const InputDecoration(labelText: 'Nomor Polisi (Plat)', hintText: 'B 1234 XYZ')),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: brandController, decoration: const InputDecoration(labelText: 'Merek'))),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(controller: modelController, decoration: const InputDecoration(labelText: 'Model'))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: yearController, decoration: const InputDecoration(labelText: 'Tahun Pembuatan'))),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(controller: rateController, decoration: const InputDecoration(labelText: 'Tarif Sewa/Hari (Rp)'))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: odoController, decoration: const InputDecoration(labelText: 'Odometer Awal (km)')),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: transmission,
                          dropdownColor: AppTheme.surfaceCard,
                          decoration: const InputDecoration(labelText: 'Transmisi'),
                          items: const [
                            DropdownMenuItem(value: 'OTOMATIS', child: Text('Otomatis (AT)')),
                            DropdownMenuItem(value: 'MANUAL', child: Text('Manual (MT)')),
                          ],
                          onChanged: (val) => setDlgState(() => transmission = val!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: category,
                          dropdownColor: AppTheme.surfaceCard,
                          decoration: const InputDecoration(labelText: 'Kategori'),
                          items: const [
                            DropdownMenuItem(value: 'CITY_CAR', child: Text('City Car')),
                            DropdownMenuItem(value: 'MPV', child: Text('MPV')),
                            DropdownMenuItem(value: 'SUV', child: Text('SUV')),
                            DropdownMenuItem(value: 'MINIBUS', child: Text('Minibus')),
                          ],
                          onChanged: (val) => setDlgState(() => category = val!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: AppTheme.textMuted))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
              onPressed: () {
                if (plateController.text.trim().isEmpty) return;
                state.addVehicle(Vehicle(
                  id: 'v-${DateTime.now().millisecondsSinceEpoch}',
                  plateNumber: plateController.text.trim().toUpperCase(),
                  vin: vinController.text.trim(),
                  engineNumber: engineController.text.trim(),
                  brand: brandController.text.trim(),
                  model: modelController.text.trim(),
                  yearMade: int.tryParse(yearController.text) ?? 2024,
                  transmission: transmission,
                  fuelType: 'BENSIN',
                  category: category,
                  odometerCurrent: int.tryParse(odoController.text) ?? 0,
                  status: VehicleStatus.tersedia,
                  dailyRate: double.tryParse(rateController.text) ?? 400000,
                ));
                Navigator.pop(ctx);
              },
              child: const Text('Simpan Kendaraan'),
            ),
          ],
        ),
      ),
    );
  }
}
