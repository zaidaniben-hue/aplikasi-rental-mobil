import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'models/models.dart';
import 'providers/app_state.dart';
import 'theme/app_theme.dart';
import 'views/login_view.dart';
import 'views/dashboard_view.dart';
import 'views/fleet_view.dart';
import 'views/rental_view.dart';
import 'views/maintenance_view.dart';
import 'views/reports_view.dart';
import 'widgets/quick_action_dialogs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..loadInitialData(),
      child: const RentDeskApp(),
    ),
  );
}

class RentDeskApp extends StatelessWidget {
  const RentDeskApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return MaterialApp(
      title: 'RentDesk - Manajemen Rental Armada',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: state.isAuthenticated ? const MainShell() : const LoginView(),
    );
  }
}

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    // Global Keyboard Shortcuts (Ctrl+N, Ctrl+F, F5)
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN): const NewBookingIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF): const SearchFleetIntent(),
        LogicalKeySet(LogicalKeyboardKey.f5): const RefreshDataIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          NewBookingIntent: CallbackAction<NewBookingIntent>(
            onInvoke: (_) => QuickActionDialogs.showNewBookingDialog(context, state),
          ),
          SearchFleetIntent: CallbackAction<SearchFleetIntent>(
            onInvoke: (_) => state.setTabIndex(1),
          ),
          RefreshDataIntent: CallbackAction<RefreshDataIntent>(
            onInvoke: (_) {
              state.evaluateAllMaintenance();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data berhasil diperbarui (F5)'), duration: Duration(seconds: 1)),
              );
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            backgroundColor: AppTheme.background,
            body: Row(
              children: [
                // Left Desktop Navigation Sidebar
                _buildSidebar(context, state),

                // Main Content View
                Expanded(
                  child: Container(
                    color: AppTheme.background,
                    child: IndexedStack(
                      index: state.currentTabIndex,
                      children: const [
                        DashboardView(),
                        FleetView(),
                        RentalView(),
                        MaintenanceView(),
                        ReportsView(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, AppState state) {
    final warningCount = state.vehicles
        .where((v) => state.getHealthForVehicle(v.id).overallHealth != HealthLevel.hijau)
        .length;

    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: AppTheme.sidebarBackground,
        border: Border(right: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        children: [
          // App Brand & Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.directions_car_filled, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RentDesk',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppTheme.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'Sistem Rental Aktif',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // User Persona / Role Switcher
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.badge_outlined, size: 16, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<UserRole>(
                      value: state.currentRole,
                      isDense: true,
                      isExpanded: true,
                      dropdownColor: AppTheme.surfaceCard,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      icon: const Icon(Icons.unfold_more, color: AppTheme.textMuted, size: 16),
                      items: UserRole.values.map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(role.label, style: const TextStyle(fontSize: 12)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) state.setRole(val);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Navigation Links
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _navItem(0, 'Ringkasan', Icons.dashboard_outlined, Icons.dashboard_rounded, state),
                _navItem(1, 'Katalog & Armada', Icons.directions_car_outlined, Icons.directions_car_rounded, state),
                _navItem(2, 'Transaksi Sewa', Icons.receipt_long_outlined, Icons.receipt_long_rounded, state),
                _navItem(
                  3,
                  'Jadwal Servis',
                  Icons.build_circle_outlined,
                  Icons.build_circle_rounded,
                  state,
                  badgeCount: warningCount,
                ),
                _navItem(4, 'Laporan & Cloud', Icons.insights_outlined, Icons.insights_rounded, state),
              ],
            ),
          ),

          // User Profile & Logout Tile
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                  child: Text(
                    state.currentUsername.isNotEmpty ? state.currentUsername[0].toUpperCase() : 'U',
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.currentUsername,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        state.currentRole.label,
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: AppTheme.danger, size: 18),
                  tooltip: 'Keluar (Logout)',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppTheme.surfaceCard,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppTheme.border)),
                        title: const Text('Konfirmasi Keluar', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
                        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: AppTheme.textMuted))),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger, foregroundColor: Colors.white),
                            onPressed: () {
                              Navigator.pop(ctx);
                              state.logout();
                            },
                            child: const Text('Keluar'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Bottom Shortcut Helper
          Container(
            margin: const EdgeInsets.fromLTRB(14, 4, 14, 14),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.keyboard_outlined, color: AppTheme.textMuted, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Pintasan Keyboard',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _shortcutTag('Ctrl + N', 'Sewa Baru'),
                _shortcutTag('Ctrl + F', 'Cari Armada'),
                _shortcutTag('F5', 'Refresh Data'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shortcutTag(String keyName, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: AppTheme.surfaceInput,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.border),
            ),
            child: Text(
              keyName,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            desc,
            style: const TextStyle(color: AppTheme.textDim, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _navItem(int index, String title, IconData icon, IconData activeIcon, AppState state, {int badgeCount = 0}) {
    final isSelected = state.currentTabIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => state.setTabIndex(index),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? Colors.white : AppTheme.textMuted,
                size: 19,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (badgeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.danger,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Intent Classes for Shortcuts
class NewBookingIntent extends Intent {
  const NewBookingIntent();
}

class SearchFleetIntent extends Intent {
  const SearchFleetIntent();
}

class RefreshDataIntent extends Intent {
  const RefreshDataIntent();
}
