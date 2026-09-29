import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final urlController = TextEditingController();
  final keyController = TextEditingController();
  bool isConnecting = false;

  @override
  void initState() {
    super.initState();
    final s = SupabaseService();
    urlController.text = s.supabaseUrl ?? '';
    keyController.text = s.supabaseAnonKey ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    final totalRevenue = state.rentals.fold(0.0, (sum, r) => sum + r.totalAmount);
    final totalOvertime = state.rentals.fold(0.0, (sum, r) => sum + r.overtimeFee);
    final totalDamage = state.rentals.fold(0.0, (sum, r) => sum + r.damageFee);
    const estimatedMaintenanceCost = 750000.0;
    final netProfit = totalRevenue - estimatedMaintenanceCost;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
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
                      'Laporan Finansial & Sinkronisasi Cloud',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ringkasan profitabilitas operasional armada dan koneksi backend Supabase PostgreSQL',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Financial Metrics Cards
            Row(
              children: [
                _metricCard('Total Omset Sewa', currency.format(totalRevenue), 'Pendapatan kotor', AppTheme.success, Icons.monetization_on_rounded),
                const SizedBox(width: 12),
                _metricCard('Denda & Surcharge', currency.format(totalOvertime + totalDamage), 'Overtime & Kerusakan', AppTheme.primary, Icons.add_chart_rounded),
                const SizedBox(width: 12),
                _metricCard('Estimasi Biaya Servis', currency.format(estimatedMaintenanceCost), 'Perawatan & bengkel', AppTheme.warning, Icons.handyman_rounded),
                const SizedBox(width: 12),
                _metricCard('Estimasi Margin Bersih', currency.format(netProfit), 'Profitabilitas bersih', AppTheme.accentPurple, Icons.savings_rounded),
              ],
            ),
            const SizedBox(height: 20),

            // Supabase Cloud Backend Configuration Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.cloud_sync_rounded, color: AppTheme.success, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Konfigurasi Supabase Cloud Backend', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                          Text('Sinkronisasi data multi-cabang kasir dan eksekusi Edge Functions', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: urlController,
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Supabase Project URL',
                            hintText: 'https://xyzcompany.supabase.co',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: keyController,
                          obscureText: true,
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Supabase Anon Key',
                            hintText: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: isConnecting
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.link_rounded, size: 18),
                        label: const Text('Simpan & Sambungkan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        onPressed: isConnecting
                            ? null
                            : () async {
                                final url = urlController.text.trim();
                                final key = keyController.text.trim();
                                final messenger = ScaffoldMessenger.of(context);
                                if (url.isEmpty || key.isEmpty) {
                                  messenger.showSnackBar(const SnackBar(content: Text('Masukkan Project URL dan Anon Key Supabase.')));
                                  return;
                                }

                                setState(() => isConnecting = true);
                                try {
                                  await SupabaseService().initialize(url: url, anonKey: key);
                                  messenger.showSnackBar(
                                    const SnackBar(backgroundColor: AppTheme.success, content: Text('Berhasil terhubung ke instance Supabase Cloud!')),
                                  );
                                } catch (e) {
                                  messenger.showSnackBar(
                                    SnackBar(backgroundColor: AppTheme.danger, content: Text('Koneksi gagal: $e')),
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(() => isConnecting = false);
                                  }
                                }
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceInput,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.textMuted),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Skema PostgreSQL terpadu dan migration SQL telah disiapkan di folder `/supabase` untuk replikasi cloud instan.',
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCard(String title, String val, String desc, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(desc, style: const TextStyle(fontSize: 11, color: AppTheme.textDim)),
          ],
        ),
      ),
    );
  }
}
