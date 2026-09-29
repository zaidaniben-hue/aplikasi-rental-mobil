import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController(text: 'kasir@rentdesk.id');
  final _passwordController = TextEditingController(text: 'rentdesk123');

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;
  UserRole _selectedRole = UserRole.frontDesk;
  String? _errorMessage;

  void _handleLogin() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    await Future.delayed(const Duration(milliseconds: 350)); // smooth natural feedback

    if (username.isEmpty || password.isEmpty) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Harap isi nama pengguna / email dan kata sandi.';
          _isLoading = false;
        });
      }
      return;
    }

    if (!mounted) return;
    final state = context.read<AppState>();
    final success = state.login(
      usernameOrEmail: username,
      password: password,
      role: _selectedRole,
    );

    if (!success && mounted) {
      setState(() {
        _errorMessage = 'Kredensial login tidak valid.';
        _isLoading = false;
      });
    }
  }

  void _quickFillDemo(UserRole role, String username) {
    setState(() {
      _selectedRole = role;
      _usernameController.text = username;
      _passwordController.text = 'rentdesk123';
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isWide ? 1040 : 480,
              minHeight: isWide ? 580 : 0,
            ),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: isWide
                  ? IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left Pane: Brand & Features Showcase
                          Expanded(
                            flex: 5,
                            child: _buildBrandingPanel(),
                          ),
                          // Divider
                          Container(width: 1, color: AppTheme.border),
                          // Right Pane: Login Form
                          Expanded(
                            flex: 6,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
                              child: _buildLoginForm(),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildMobileBrandHeader(),
                          const SizedBox(height: 24),
                          _buildLoginForm(),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandingPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
      decoration: BoxDecoration(
        color: AppTheme.sidebarBackground,
        gradient: LinearGradient(
          colors: [
            AppTheme.sidebarBackground,
            AppTheme.surface.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo & Name
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.directions_car_filled, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RentDesk',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Sistem Manajemen Armada & POS Kasir',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 36),
              const Text(
                'Kelola Rental Armada dengan Presisi & Efisiensi Tinggi',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  height: 1.3,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Aplikasi desktop terpadu untuk monitoring unit, serah terima cepat, kalkulasi denda otomatis, dan keselamatan kendaraan.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 28),

              // Feature Highlights
              _featureBullet(
                icon: Icons.flash_on_rounded,
                color: AppTheme.primary,
                title: 'Alur Kasir Cepat',
                desc: 'Registrasi sewa & cetak struk termal dalam < 3 menit.',
              ),
              const SizedBox(height: 14),
              _featureBullet(
                icon: Icons.shield_rounded,
                color: AppTheme.success,
                title: 'Inspeksi Bodi Visual',
                desc: 'Tandai titik lecet bodi kendaraan secara interaktif.',
              ),
              const SizedBox(height: 14),
              _featureBullet(
                icon: Icons.build_circle_rounded,
                color: AppTheme.warning,
                title: 'Auto-Lock Servis Berkala',
                desc: 'Proteksi armada mogok dengan kunci unit otomatis jatuh tempo.',
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Bottom System Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceInput,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Sistem Siap Operasional • Offline Ready & Cloud Sync',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureBullet({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 1),
              Text(desc, style: const TextStyle(fontSize: 11, color: AppTheme.textDim)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileBrandHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF6366F1)]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.directions_car_filled, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('RentDesk', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Manajemen Rental Armada', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          ],
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Selamat Datang Kembali',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Silakan masuk dengan akun petugas atau pilih peran demo',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 20),

          // Role Selector Tabs
          const Text(
            'PILIH HAK AKSES / PERAN:',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _roleOption(
                  role: UserRole.frontDesk,
                  label: 'Kasir',
                  icon: Icons.person_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _roleOption(
                  role: UserRole.mechanic,
                  label: 'Mekanik',
                  icon: Icons.build_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _roleOption(
                  role: UserRole.manager,
                  label: 'Manajer',
                  icon: Icons.admin_panel_settings_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Error Message Alert
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.danger.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Username / Email field
          const Text('Nama Pengguna atau Email', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _usernameController,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'nama@rentdesk.id atau username',
              prefixIcon: Icon(Icons.account_circle_outlined, size: 18, color: AppTheme.textMuted),
            ),
          ),
          const SizedBox(height: 14),

          // Password field
          const Text('Kata Sandi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
            onFieldSubmitted: (_) => _handleLogin(),
            decoration: InputDecoration(
              hintText: '••••••••••••',
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: AppTheme.textMuted),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18,
                  color: AppTheme.textMuted,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Remember Me Checkbox
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _rememberMe,
                      activeColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: (val) => setState(() => _rememberMe = val ?? true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Ingat sesi login', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
              Text(
                'Lupa sandi?',
                style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Login Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Masuk ke Sistem', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // Quick Demo Fill
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
                const Row(
                  children: [
                    Icon(Icons.touch_app_rounded, size: 14, color: AppTheme.primary),
                    SizedBox(width: 6),
                    Text(
                      'Pintasan Uji Coba Cepat (Demo):',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _demoChip(
                      label: 'Kasir Front Desk',
                      role: UserRole.frontDesk,
                      email: 'kasir@rentdesk.id',
                    ),
                    _demoChip(
                      label: 'Koordinator Mekanik',
                      role: UserRole.mechanic,
                      email: 'mekanik@rentdesk.id',
                    ),
                    _demoChip(
                      label: 'Manajer / Owner',
                      role: UserRole.manager,
                      email: 'owner@rentdesk.id',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleOption({
    required UserRole role,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == role;
    return InkWell(
      onTap: () => setState(() => _selectedRole = role),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.18) : AppTheme.surfaceInput,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppTheme.primary : AppTheme.textMuted,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppTheme.textPrimary : AppTheme.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _demoChip({
    required String label,
    required UserRole role,
    required String email,
  }) {
    return InkWell(
      onTap: () => _quickFillDemo(role, email),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.border),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
