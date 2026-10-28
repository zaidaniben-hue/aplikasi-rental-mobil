import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/quick_action_dialogs.dart';
import '../widgets/thermal_receipt_dialog.dart';

class RentalView extends StatefulWidget {
  const RentalView({super.key});

  @override
  State<RentalView> createState() => _RentalViewState();
}

class _RentalViewState extends State<RentalView> {
  String _filterStatus = 'ALL'; // 'ALL', 'ACTIVE', 'BOOKED', 'COMPLETED'
  String _searchQuery = '';
  final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    final filteredRentals = state.rentals.where((r) {
      if (_filterStatus != 'ALL' && r.rentalStatus != _filterStatus) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesCode = r.transactionCode.toLowerCase().contains(q);
        final matchesCust = r.customer?.fullName.toLowerCase().contains(q) ?? false;
        final matchesPlate = r.vehicle?.plateNumber.toLowerCase().contains(q) ?? false;
        if (!matchesCode && !matchesCust && !matchesPlate) return false;
      }
      return true;
    }).toList();

    final countActive = state.rentals.where((r) => r.rentalStatus == 'ACTIVE').length;
    final countBooked = state.rentals.where((r) => r.rentalStatus == 'BOOKED').length;
    final countCompleted = state.rentals.where((r) => r.rentalStatus == 'COMPLETED').length;

    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            if (isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Transaksi Sewa & Kasir',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Pencatatan serah terima (Check-in/Check-out) & kasir',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF10B981),
                            side: const BorderSide(color: Color(0xFF10B981)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.hub_rounded, size: 16),
                          label: const Text('Screening AI (NB)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () => _showNaiveBayesScreeningDialog(context, state),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                          label: const Text('Sewa Baru', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          onPressed: () => QuickActionDialogs.showNewBookingDialog(context, state),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transaksi Sewa & Kasir',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.5),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Pencatatan serah terima (Check-in/Check-out), kalkulasi denda otomatis, dan prediksi risiko berbasis ML',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF10B981),
                          side: const BorderSide(color: Color(0xFF10B981)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.hub_rounded, size: 16),
                        label: const Text('Screening Pelanggan (Naive Bayes AI)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () => _showNaiveBayesScreeningDialog(context, state),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                        label: const Text('Sewa Baru (Ctrl+N)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        onPressed: () => QuickActionDialogs.showNewBookingDialog(context, state),
                      ),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 16),

            // Search Bar & Filter Strip
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          onChanged: (val) => setState(() => _searchQuery = val),
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Cari kode, penyewa, atau plat...',
                            prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppTheme.textMuted),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 16, color: AppTheme.textMuted),
                                    onPressed: () => setState(() => _searchQuery = ''),
                                  )
                                : null,
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                        const Divider(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _statusTab('ALL', 'Semua (${state.rentals.length})', AppTheme.primary),
                              const SizedBox(width: 8),
                              _statusTab('ACTIVE', 'Disewa ($countActive)', AppTheme.accentPurple),
                              const SizedBox(width: 8),
                              _statusTab('BOOKED', 'Booking ($countBooked)', AppTheme.primary),
                              const SizedBox(width: 8),
                              _statusTab('COMPLETED', 'Selesai ($countCompleted)', AppTheme.success),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        // Search Input
                        Expanded(
                          flex: 3,
                          child: TextField(
                            onChanged: (val) => setState(() => _searchQuery = val),
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Cari kode booking, nama penyewa, atau plat nomor...',
                              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppTheme.textMuted),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 16, color: AppTheme.textMuted),
                                      onPressed: () => setState(() => _searchQuery = ''),
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
                        Container(width: 1, height: 28, color: AppTheme.border),
                        const SizedBox(width: 12),
                        // Filter Status Pills
                        _statusTab('ALL', 'Semua (${state.rentals.length})', AppTheme.primary),
                        const SizedBox(width: 8),
                        _statusTab('ACTIVE', 'Sedang Disewa ($countActive)', AppTheme.accentPurple),
                        const SizedBox(width: 8),
                        _statusTab('BOOKED', 'Booking ($countBooked)', AppTheme.primary),
                        const SizedBox(width: 8),
                        _statusTab('COMPLETED', 'Selesai ($countCompleted)', AppTheme.success),
                      ],
                    ),
            ),
            const SizedBox(height: 16),

            // Transactions Table / Cards List
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: filteredRentals.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_rounded, size: 48, color: AppTheme.border),
                              SizedBox(height: 12),
                              Text('Tidak ada data transaksi yang sesuai filter.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: filteredRentals.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, idx) {
                            final rental = filteredRentals[idx];
                            final isActive = rental.rentalStatus == 'ACTIVE';
                            final isBooked = rental.rentalStatus == 'BOOKED';

                            Color badgeColor = isActive
                                ? AppTheme.accentPurple
                                : isBooked
                                    ? AppTheme.primary
                                    : AppTheme.success;

                            if (isMobile) {
                              return Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Row 1: Code + Badge + Print Button
                                    Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: badgeColor.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                                          ),
                                          child: Icon(
                                            isActive
                                                ? Icons.car_rental_rounded
                                                : isBooked
                                                    ? Icons.bookmark_added_rounded
                                                    : Icons.check_circle_outline_rounded,
                                            color: badgeColor,
                                            size: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          rental.transactionCode,
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, fontFamily: 'monospace', color: AppTheme.textPrimary),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: badgeColor.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                                          ),
                                          child: Text(
                                            rental.rentalStatus,
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                                          ),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          icon: const Icon(Icons.print_outlined, size: 20, color: AppTheme.textMuted),
                                          tooltip: 'Cetak Struk',
                                          onPressed: () => showDialog(
                                            context: context,
                                            builder: (_) => ThermalReceiptDialog(rental: rental),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    // Row 2: Vehicle & Customer
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.surfaceInput,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: AppTheme.border),
                                          ),
                                          child: Text(
                                            rental.vehicle?.plateNumber ?? '-',
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, fontFamily: 'monospace', color: AppTheme.textPrimary),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${rental.vehicle?.brand ?? ''} ${rental.vehicle?.model ?? ''}',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Penyewa: ${rental.customer?.fullName ?? '-'} • ${rental.customer?.phoneNumber ?? ''}',
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${dateFormat.format(rental.startTime)} s/d ${dateFormat.format(rental.plannedEndTime)}',
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                    ),
                                    const SizedBox(height: 6),
                                    _buildAiRentalChips(context, state, rental),
                                    const Divider(height: 16),
                                    // Row 3: Financial & Action Button
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              currency.format(rental.totalAmount),
                                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.success),
                                            ),
                                            Text(
                                              '${rental.durationDays} Hari • Dep: ${currency.format(rental.depositAmount)}',
                                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                            ),
                                            if (rental.overtimeFee > 0)
                                              Text(
                                                '+ Denda ${currency.format(rental.overtimeFee)}',
                                                style: const TextStyle(fontSize: 10, color: AppTheme.warning, fontWeight: FontWeight.bold),
                                              ),
                                          ],
                                        ),
                                        if (rental.rentalStatus == 'BOOKED')
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.accentPurple,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            icon: const Icon(Icons.key_rounded, size: 14),
                                            label: const Text('Check-Out', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                            onPressed: () => QuickActionDialogs.showCheckoutDialog(context, state, rental),
                                          )
                                        else if (rental.rentalStatus == 'ACTIVE')
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.success,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            icon: const Icon(Icons.assignment_turned_in_rounded, size: 14),
                                            label: const Text('Check-In', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                            onPressed: () => QuickActionDialogs.showCheckinDialog(context, state, rental),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  // Icon status container
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: badgeColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                                    ),
                                    child: Icon(
                                      isActive
                                          ? Icons.car_rental_rounded
                                          : isBooked
                                              ? Icons.bookmark_added_rounded
                                              : Icons.check_circle_outline_rounded,
                                      color: badgeColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Code & Customer
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              rental.transactionCode,
                                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, fontFamily: 'monospace', color: AppTheme.textPrimary),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: badgeColor.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                                              ),
                                              child: Text(
                                                rental.rentalStatus,
                                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${rental.customer?.fullName ?? '-'} • ${rental.customer?.phoneNumber ?? ''}',
                                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                        ),
                                        const SizedBox(height: 6),
                                        _buildAiRentalChips(context, state, rental),
                                      ],
                                    ),
                                  ),

                                  // Vehicle
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppTheme.surfaceInput,
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: AppTheme.border),
                                              ),
                                              child: Text(
                                                rental.vehicle?.plateNumber ?? '-',
                                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, fontFamily: 'monospace', color: AppTheme.textPrimary),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '${rental.vehicle?.brand ?? ''} ${rental.vehicle?.model ?? ''}',
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${dateFormat.format(rental.startTime)} s/d ${dateFormat.format(rental.plannedEndTime)}',
                                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Financial
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          currency.format(rental.totalAmount),
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.success),
                                        ),
                                        Text(
                                          '${rental.durationDays} Hari • Dep: ${currency.format(rental.depositAmount)}',
                                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                        ),
                                        if (rental.overtimeFee > 0)
                                          Text(
                                            '+ Denda ${currency.format(rental.overtimeFee)}',
                                            style: const TextStyle(fontSize: 10, color: AppTheme.warning, fontWeight: FontWeight.bold),
                                          ),
                                      ],
                                    ),
                                  ),

                                  // Actions
                                  Wrap(
                                    spacing: 8,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      if (rental.rentalStatus == 'BOOKED')
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.accentPurple,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                          icon: const Icon(Icons.key_rounded, size: 14),
                                          label: const Text('Check-Out', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          onPressed: () => QuickActionDialogs.showCheckoutDialog(context, state, rental),
                                        ),
                                      if (rental.rentalStatus == 'ACTIVE')
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.success,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                          icon: const Icon(Icons.assignment_turned_in_rounded, size: 14),
                                          label: const Text('Check-In', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          onPressed: () => QuickActionDialogs.showCheckinDialog(context, state, rental),
                                        ),
                                      IconButton(
                                        icon: const Icon(Icons.print_outlined, size: 18, color: AppTheme.textMuted),
                                        tooltip: 'Cetak Struk Termal POS',
                                        onPressed: () => showDialog(
                                          context: context,
                                          builder: (_) => ThermalReceiptDialog(rental: rental),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
    );
  }

  Widget _statusTab(String key, String label, Color color) {
    final isSelected = _filterStatus == key;
    return InkWell(
      onTap: () => setState(() => _filterStatus = key),
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
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? color : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // MACHINE LEARNING: LOGISTIC REGRESSION (OVERTIME RISK) & NAIVE BAYES (SCREENING)
  // =========================================================================

  Widget _buildAiRentalChips(BuildContext context, AppState state, Rental rental) {
    final probLate = state.getPredictedRentalLateProbability(rental);
    final isHighRisk = probLate > 0.55;
    final isModerate = probLate > 0.35 && !isHighRisk;
    final riskColor = isHighRisk ? AppTheme.danger : (isModerate ? AppTheme.warning : AppTheme.success);
    final riskPercent = (probLate * 100).toStringAsFixed(0);

    final customer = rental.customer;
    final nb = customer != null ? state.getCustomerEligibility(customer) : null;
    final isLayak = nb?.bestClass == 'LAYAK SEWA (Aman)';
    final isTolak = nb?.bestClass == 'TOLAK / BLACKLIST';
    final nbColor = isLayak ? AppTheme.success : (isTolak ? AppTheme.danger : AppTheme.warning);

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        // 1. Logistic Regression Late Risk Chip
        InkWell(
          onTap: () => _showLogisticRegressionRiskModal(context, state, rental, probLate),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: riskColor.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.alt_route_rounded, size: 11, color: riskColor),
                const SizedBox(width: 4),
                Text(
                  'Risiko Telat: $riskPercent%',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: riskColor),
                ),
                const SizedBox(width: 2),
                Icon(Icons.info_outline_rounded, size: 10, color: riskColor.withValues(alpha: 0.7)),
              ],
            ),
          ),
        ),

        // 2. Naive Bayes Customer Screening Chip
        if (customer != null && nb != null)
          InkWell(
            onTap: () => _showCustomerEligibilityModal(context, state, customer, nb),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: nbColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: nbColor.withValues(alpha: 0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_user_outlined, size: 11, color: nbColor),
                  const SizedBox(width: 4),
                  Text(
                    'NB: ${isLayak ? 'Layak' : (isTolak ? 'Tolak' : 'Verifikasi')}',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: nbColor),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showLogisticRegressionRiskModal(BuildContext context, AppState state, Rental rental, double probLate) {
    final log = state.mlService.logisticRegression;
    final isHigh = probLate > 0.55;
    final color = isHigh ? AppTheme.danger : (probLate > 0.35 ? AppTheme.warning : AppTheme.success);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.border)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.alt_route_rounded, color: Color(0xFFF59E0B), size: 18),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Analisis Risiko Telat (Logistic Regression)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ),
          ],
        ),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Result Probability Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Peluang Terlambat Kembali (Overtime):', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        const SizedBox(height: 2),
                        Text(
                          isHigh ? 'RISIKO TINGGI (Perlu Tindakan)' : (probLate > 0.35 ? 'RISIKO MODERAT' : 'AMAN (Tepat Waktu)'),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
                        ),
                      ],
                    ),
                    Text(
                      '${(probLate * 100).toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              const Text('Faktor Prediksi Log-Odds:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.surfaceInput, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.border)),
                child: Column(
                  children: [
                    _riskFactorRow('Durasi Sewa Unit:', '${rental.durationDays} Hari', Icons.calendar_month_outlined),
                    _riskFactorRow('Riwayat Overdue Pelanggan:', rental.overtimeFee > 0 ? 'Pernah Telat (Bobot +)' : 'Belum Pernah Telat', Icons.history_rounded),
                    _riskFactorRow('Estimasi KM / Hari:', '±75 km / hari', Icons.speed_rounded),
                    _riskFactorRow('Akurasi Model Sigmoid:', '${(log.accuracy * 100).toStringAsFixed(0)}% (Log-Loss: ${log.logLoss.toStringAsFixed(2)})', Icons.analytics_outlined),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rekomendasi Petugas Kasir:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    const SizedBox(height: 4),
                    Text(
                      isHigh
                          ? '• Ambil jaminan deposit ekstra sebesar Rp 500.000.\n• Jadwalkan reminder WhatsApp otomatis 3 jam sebelum batas akhir pengembalian.'
                          : '• Transaksi dinilai aman. Terapkan SOP standar penyerahan kunci.',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  Widget _riskFactorRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.textMuted),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  void _showCustomerEligibilityModal(BuildContext context, AppState state, Customer customer, dynamic nb) {
    final bestClass = nb.bestClass as String;
    final isLayak = bestClass == 'LAYAK SEWA (Aman)';
    final isTolak = bestClass == 'TOLAK / BLACKLIST';
    final color = isLayak ? AppTheme.success : (isTolak ? AppTheme.danger : AppTheme.warning);
    final probs = nb.probabilities as Map<String, double>;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.border)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.hub_rounded, color: Color(0xFF10B981), size: 18),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Screening Pelanggan (Naive Bayes AI)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ),
          ],
        ),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(customer.fullName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        Text('NIK: ${customer.nik} • SIM: ${customer.simNumber}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        bestClass.split(' ').first,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              const Text('Distribusi Posterior Bayesian P(C | Dokumen, Domisili, Kontak):', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              const SizedBox(height: 6),
              ...probs.entries.map((e) {
                final pct = (e.value * 100).toStringAsFixed(1);
                final cColor = e.key.contains('Aman') ? AppTheme.success : (e.key.contains('TOLAK') ? AppTheme.danger : AppTheme.warning);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      SizedBox(width: 140, child: Text(e.key, style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary))),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: e.value,
                            backgroundColor: AppTheme.surfaceInput,
                            valueColor: AlwaysStoppedAnimation<Color>(cColor),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('$pct%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cColor)),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showNaiveBayesScreeningDialog(BuildContext context, AppState state) {
    double simDoc = 3.0; // 3: Lengkap, 2: KTP saja, 1: Kurang
    bool simLocal = true;
    double simJob = 3.0; // 3: Tetap, 2: Wiraswasta, 1: Tidak Tetap
    bool simEmergency = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final res = state.mlService.screenCustomerEligibility(
            docScore: simDoc,
            isLocalDomicile: simLocal,
            jobStatusScore: simJob,
            hasEmergencyContact: simEmergency,
          );
          final isLayak = res.bestClass == 'LAYAK SEWA (Aman)';
          final isTolak = res.bestClass == 'TOLAK / BLACKLIST';
          final resColor = isLayak ? AppTheme.success : (isTolak ? AppTheme.danger : AppTheme.warning);

          return Dialog(
            backgroundColor: AppTheme.surfaceCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.border)),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
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
                              decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.hub_rounded, color: Color(0xFF10B981), size: 18),
                            ),
                            const SizedBox(width: 10),
                            const Text('Screening Calon Pelanggan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                          ],
                        ),
                        IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted)),
                      ],
                    ),
                    const Divider(height: 20),

                    // Result Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: resColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: resColor.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Hasil Rekomendasi Naive Bayes:', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                              SizedBox(height: 2),
                              Text('Teorema Peluang Posterior Bayes', style: TextStyle(fontSize: 10, color: AppTheme.textDim)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: resColor, borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              res.bestClass,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Inputs
                    const Text('Kelengkapan Dokumen Identitas:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<double>(
                      initialValue: simDoc,
                      isExpanded: true,
                      dropdownColor: AppTheme.surfaceCard,
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      items: const [
                        DropdownMenuItem(value: 3.0, child: Text('Lengkap: e-KTP + SIM A Asli Valid', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 2.0, child: Text('Parsial: e-KTP Valid Saja (SIM Resi)', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 1.0, child: Text('Tidak Lengkap / Foto Tidak Jelas', overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (val) => setDlgState(() => simDoc = val ?? 3.0),
                    ),
                    const SizedBox(height: 12),

                    const Text('Status Domisili Tempat Tinggal:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<bool>(
                      initialValue: simLocal,
                      isExpanded: true,
                      dropdownColor: AppTheme.surfaceCard,
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      items: const [
                        DropdownMenuItem(value: true, child: Text('Domisili Lokal (KTP & Tempat Tinggal Sama)', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: false, child: Text('Luar Kota / Wisatawan Tanpa Domisili Tetap', overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (val) => setDlgState(() => simLocal = val ?? true),
                    ),
                    const SizedBox(height: 12),

                    const Text('Status Pekerjaan & Penghasilan:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<double>(
                      initialValue: simJob,
                      isExpanded: true,
                      dropdownColor: AppTheme.surfaceCard,
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      items: const [
                        DropdownMenuItem(value: 3.0, child: Text('Karyawan Tetap / BUMN / PNS', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 2.0, child: Text('Wiraswasta / Profesional Mandiri', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 1.0, child: Text('Tidak Tetap / Mahasiswa Tanpa Penjamin', overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (val) => setDlgState(() => simJob = val ?? 3.0),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Kontak Darurat Terverifikasi:', style: TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
                        Switch(
                          value: simEmergency,
                          activeThumbColor: const Color(0xFF10B981),
                          onChanged: (val) => setDlgState(() => simEmergency = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Selesai Screening'),
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
