import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Transaksi Sewa & Kasir',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pencatatan serah terima (Check-in/Check-out), kalkulasi denda otomatis, dan cetak invoice struk',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
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
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                  label: const Text('Sewa Baru (Ctrl+N)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  onPressed: () => QuickActionDialogs.showNewBookingDialog(context, state),
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
              child: Row(
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
                                            Text(
                                              '${rental.vehicle?.brand ?? ''} ${rental.vehicle?.model ?? ''}',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
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
}
