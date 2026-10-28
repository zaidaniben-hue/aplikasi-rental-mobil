import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'models/models.dart';
import 'providers/app_state.dart';
import 'theme/app_theme.dart';
import 'views/login_view.dart';
import 'views/dashboard_view.dart';
import 'views/fleet_view.dart';
import 'services/supabase_service.dart';
import 'views/rental_view.dart';
import 'views/maintenance_view.dart';
import 'views/reports_view.dart';
import 'views/inspection_log_view.dart';
import 'widgets/quick_action_dialogs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase backend automatically
  try {
    await SupabaseService().initialize();
    debugPrint('Supabase initialized successfully!');
  } catch (e) {
    debugPrint('Supabase initialization failed/skipped: $e');
  }

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
    final isMobile = MediaQuery.of(context).size.width < 800;
    final warningCount = state.vehicles
        .where((v) => state.getHealthForVehicle(v.id).overallHealth != HealthLevel.hijau)
        .length;

    final navItems = _getNavItems(state, warningCount);
    final safeIndex = state.currentTabIndex.clamp(0, navItems.length - 1);

    Widget content = isMobile
        ? Scaffold(
            backgroundColor: AppTheme.background,
            appBar: AppBar(
              backgroundColor: AppTheme.sidebarBackground,
              elevation: 0,
              scrolledUnderElevation: 0,
              titleSpacing: 0,
              iconTheme: const IconThemeData(color: AppTheme.textPrimary),
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.directions_car_filled, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'RentDesk',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  icon: state.isSyncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                        )
                      : Icon(
                          SupabaseService().isConnected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                          color: SupabaseService().isConnected ? AppTheme.success : AppTheme.textMuted,
                          size: 19,
                        ),
                  tooltip: SupabaseService().isConnected ? 'Tersambung ke Supabase (Ketuk untuk Sinkronkan)' : 'Supabase Terputus',
                  onPressed: state.isSyncing ? null : () => state.syncWithSupabase(),
                ),
                PopupMenuButton<UserRole>(
                  tooltip: 'Ganti Peran Pengguna (${state.currentRole.label})',
                  color: AppTheme.surfaceCard,
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: AppTheme.border),
                  ),
                  onSelected: (val) => state.setRole(val),
                  itemBuilder: (ctx) => UserRole.values.map((role) {
                    final isSel = role == state.currentRole;
                    return PopupMenuItem(
                      value: role,
                      child: Row(
                        children: [
                          Icon(
                            role == UserRole.mechanic
                                ? Icons.build_circle_outlined
                                : (role == UserRole.frontDesk ? Icons.receipt_long_outlined : Icons.admin_panel_settings_outlined),
                            size: 16,
                            color: isSel ? AppTheme.primary : AppTheme.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            role.label,
                            style: TextStyle(
                              color: isSel ? AppTheme.primary : AppTheme.textPrimary,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          state.currentRole == UserRole.mechanic
                              ? Icons.handyman_rounded
                              : (state.currentRole == UserRole.frontDesk ? Icons.badge_outlined : Icons.shield_outlined),
                          size: 13,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          state.currentRole == UserRole.mechanic
                              ? 'Mekanik'
                              : (state.currentRole == UserRole.frontDesk ? 'Kasir' : 'Manajer'),
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.arrow_drop_down, color: AppTheme.textMuted, size: 14),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  icon: const Icon(Icons.logout_rounded, color: AppTheme.danger, size: 19),
                  tooltip: 'Keluar',
                  onPressed: () => _confirmLogout(context, state),
                ),
              ],
            ),
            drawer: _buildDrawer(context, state, warningCount, navItems),
            body: SafeArea(
              top: false,
              child: IndexedStack(
                index: safeIndex,
                children: navItems.map((item) => item.view).toList(),
              ),
            ),
            bottomNavigationBar: NavigationBarTheme(
              data: NavigationBarThemeData(
                backgroundColor: AppTheme.sidebarBackground,
                indicatorColor: AppTheme.primary.withValues(alpha: 0.25),
                height: 64,
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold);
                  }
                  return const TextStyle(color: AppTheme.textMuted, fontSize: 10);
                }),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const IconThemeData(color: AppTheme.primary, size: 22);
                  }
                  return const IconThemeData(color: AppTheme.textMuted, size: 20);
                }),
              ),
              child: NavigationBar(
                selectedIndex: safeIndex,
                onDestinationSelected: (idx) => state.setTabIndex(idx),
                destinations: navItems.map((item) {
                  return NavigationDestination(
                    icon: item.badgeCount != null && item.badgeCount! > 0
                        ? Badge(
                            label: Text(item.badgeCount.toString()),
                            child: Icon(item.icon),
                          )
                        : Icon(item.icon),
                    selectedIcon: item.badgeCount != null && item.badgeCount! > 0
                        ? Badge(
                            label: Text(item.badgeCount.toString()),
                            child: Icon(item.selectedIcon),
                          )
                        : Icon(item.selectedIcon),
                    label: item.label,
                  );
                }).toList(),
              ),
            ),
          )
        : Scaffold(
            backgroundColor: AppTheme.background,
            body: Row(
              children: [
                // Left Desktop Navigation Sidebar
                _buildSidebar(context, state, navItems),

                // Main Content View
                Expanded(
                  child: Container(
                    color: AppTheme.background,
                    child: IndexedStack(
                      index: safeIndex,
                      children: navItems.map((item) => item.view).toList(),
                    ),
                  ),
                ),
              ],
            ),
          );

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
              state.syncWithSupabase();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Menyinkronkan dengan database Supabase (F5)...'), duration: Duration(seconds: 1)),
              );
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: content,
        ),
      ),
    );
  }

  List<NavItemConfig> _getNavItems(AppState state, int warningCount) {
    switch (state.currentRole) {
      case UserRole.mechanic:
        return [
          NavItemConfig(
            label: 'Jadwal Servis',
            icon: Icons.build_circle_outlined,
            selectedIcon: Icons.build_circle_rounded,
            badgeCount: warningCount,
            view: const MaintenanceView(),
          ),
          const NavItemConfig(
            label: 'Kondisi Armada',
            icon: Icons.directions_car_outlined,
            selectedIcon: Icons.directions_car_rounded,
            view: FleetView(),
          ),
          const NavItemConfig(
            label: 'Log Kerusakan',
            icon: Icons.car_crash_outlined,
            selectedIcon: Icons.car_crash_rounded,
            view: InspectionLogView(),
          ),
          const NavItemConfig(
            label: 'Pusat Bengkel',
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard_rounded,
            view: DashboardView(),
          ),
        ];
      case UserRole.frontDesk:
        return [
          const NavItemConfig(
            label: 'Pusat Kasir',
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard_rounded,
            view: DashboardView(),
          ),
          const NavItemConfig(
            label: 'Katalog Armada',
            icon: Icons.directions_car_outlined,
            selectedIcon: Icons.directions_car_rounded,
            view: FleetView(),
          ),
          const NavItemConfig(
            label: 'Transaksi Sewa',
            icon: Icons.receipt_long_outlined,
            selectedIcon: Icons.receipt_long_rounded,
            view: RentalView(),
          ),
          NavItemConfig(
            label: 'Cek Servis',
            icon: Icons.build_circle_outlined,
            selectedIcon: Icons.build_circle_rounded,
            badgeCount: warningCount,
            view: const MaintenanceView(),
          ),
        ];
      case UserRole.manager:
        return [
          const NavItemConfig(
            label: 'Ringkasan',
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard_rounded,
            view: DashboardView(),
          ),
          const NavItemConfig(
            label: 'Katalog Armada',
            icon: Icons.directions_car_outlined,
            selectedIcon: Icons.directions_car_rounded,
            view: FleetView(),
          ),
          const NavItemConfig(
            label: 'Transaksi Sewa',
            icon: Icons.receipt_long_outlined,
            selectedIcon: Icons.receipt_long_rounded,
            view: RentalView(),
          ),
          NavItemConfig(
            label: 'Jadwal Servis',
            icon: Icons.build_circle_outlined,
            selectedIcon: Icons.build_circle_rounded,
            badgeCount: warningCount,
            view: const MaintenanceView(),
          ),
          const NavItemConfig(
            label: 'Laporan & Cloud',
            icon: Icons.insights_outlined,
            selectedIcon: Icons.insights_rounded,
            view: ReportsView(),
          ),
        ];
    }
  }

  void _confirmLogout(BuildContext context, AppState state) {
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
  }

  Widget _buildDrawer(BuildContext context, AppState state, int warningCount, List<NavItemConfig> navItems) {
    return Drawer(
      backgroundColor: AppTheme.sidebarBackground,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.directions_car_filled, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RentDesk',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Rental Armada Mobile',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // User Persona switcher in drawer
            Container(
              margin: const EdgeInsets.all(14),
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
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (int i = 0; i < navItems.length; i++)
                    _navItem(
                      i,
                      navItems[i].label,
                      navItems[i].icon,
                      navItems[i].selectedIcon,
                      state,
                      badgeCount: navItems[i].badgeCount ?? 0,
                      onTap: () {
                        state.setTabIndex(i);
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
            ),
            // User Card & Logout
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                    tooltip: 'Keluar',
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmLogout(context, state);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, AppState state, List<NavItemConfig> navItems) {
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
                        InkWell(
                          onTap: state.isSyncing ? null : () => state.syncWithSupabase(),
                          borderRadius: BorderRadius.circular(4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              state.isSyncing
                                  ? const SizedBox(
                                      width: 8,
                                      height: 8,
                                      child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.primary),
                                    )
                                  : Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: SupabaseService().isConnected ? AppTheme.success : AppTheme.warning,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                              const SizedBox(width: 5),
                              Text(
                                state.isSyncing
                                    ? 'Sinkronisasi Supabase...'
                                    : (SupabaseService().isConnected ? 'Supabase Terhubung' : 'Supabase Offline'),
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
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
                for (int i = 0; i < navItems.length; i++)
                  _navItem(
                    i,
                    navItems[i].label,
                    navItems[i].icon,
                    navItems[i].selectedIcon,
                    state,
                    badgeCount: navItems[i].badgeCount ?? 0,
                  ),
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
                  onPressed: () => _confirmLogout(context, state),
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

  Widget _navItem(int index, String title, IconData icon, IconData activeIcon, AppState state, {int badgeCount = 0, VoidCallback? onTap}) {
    final isSelected = state.currentTabIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap ?? () => state.setTabIndex(index),
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

// Helper item for role-driven navigation
class NavItemConfig {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget view;
  final int? badgeCount;

  const NavItemConfig({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.view,
    this.badgeCount,
  });
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
