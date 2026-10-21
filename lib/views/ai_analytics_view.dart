import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/machine_learning/ml_service.dart';
import '../theme/app_theme.dart';

class AiAnalyticsView extends StatefulWidget {
  const AiAnalyticsView({super.key});

  @override
  State<AiAnalyticsView> createState() => _AiAnalyticsViewState();
}

class _AiAnalyticsViewState extends State<AiAnalyticsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  // State untuk Simulator 1: Linear Regression
  double _simKm = 45000;
  double _simAge = 3;

  // State untuk Simulator 2: Logistic Regression
  double _simRentalDays = 4;
  bool _simHasPastLate = true;
  double _simKmPerDay = 160;
  double _simCustomerAge = 25;

  // State untuk Simulator 3: Naive Bayes
  double _simDocCompleteness = 3.0; // 3: Lengkap, 2: KTP saja, 1: Kurang
  double _simLocalDomicile = 1.0;    // 1: Lokal, 0: Luar Kota
  double _simJobStatus = 3.0;        // 3: Tetap, 2: Wiraswasta, 1: Tidak Menentu
  double _simEmergencyContact = 1.0; // 1: Ada, 0: Tidak

  // State untuk Simulator 4: SVM
  double _simKmSinceService = 4500;
  double _simDefectCount = 1;
  double _simComplaintScore = 2; // 1 s/d 10

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final ml = state.mlService;
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header Banner
            _buildHeader(context, state, ml, isMobile),
            const SizedBox(height: 16),

            // Top Summary Cards (4 Models Performance)
            _buildModelStatusGrid(ml, isMobile),
            const SizedBox(height: 20),

            // Algorithm Selector Tabs
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: isMobile,
                indicatorColor: AppTheme.primary,
                indicatorWeight: 3,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textMuted,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(icon: Icon(Icons.show_chart_rounded, size: 18), text: '1. Linear Regression'),
                  Tab(icon: Icon(Icons.alt_route_rounded, size: 18), text: '2. Logistic Regression'),
                  Tab(icon: Icon(Icons.hub_rounded, size: 18), text: '3. Naive Bayes'),
                  Tab(icon: Icon(Icons.shield_outlined, size: 18), text: '4. Support Vector Machine'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab Views Container
            AnimatedBuilder(
              animation: _tabController,
              builder: (ctx, _) {
                switch (_tabController.index) {
                  case 0:
                    return _buildLinearRegressionTab(ml, isMobile);
                  case 1:
                    return _buildLogisticRegressionTab(ml, isMobile);
                  case 2:
                    return _buildNaiveBayesTab(ml, isMobile);
                  case 3:
                  default:
                    return _buildSvmTab(ml, isMobile);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppState state, MlService ml, bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Pure-Dart ML Engine Online',
                          style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'AI & Machine Learning Center',
                style: TextStyle(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Implementasi 4 model kecerdasan buatan mandiri (tanpa server eksternal) untuk optimasi prediksi armada dan risiko operasional.',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
        if (!isMobile)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.sync_rounded, size: 16),
            label: const Text('Latih Ulang Model', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            onPressed: () {
              state.reTrainMlModels();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Semua 4 model Machine Learning berhasil dilatih ulang dengan data armada terkini!'),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildModelStatusGrid(MlService ml, bool isMobile) {
    final lin = ml.linearRegression;
    final log = ml.logisticRegression;
    final nb = ml.naiveBayes;
    final svm = ml.svmClassifier;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 600 ? 1 : (constraints.maxWidth < 1000 ? 2 : 4);
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: crossAxisCount == 1 ? 3.0 : 1.7,
          children: [
            _metricMiniCard(
              title: 'Linear Regression',
              subtitle: 'Prediksi Biaya Servis',
              metricLabel: 'R² Score: ${(lin.r2Score * 100).toStringAsFixed(1)}%',
              status: 'Terlatih (OLS/GD)',
              color: const Color(0xFF3B82F6),
              icon: Icons.show_chart_rounded,
            ),
            _metricMiniCard(
              title: 'Logistic Regression',
              subtitle: 'Peluang Telat (Overtime)',
              metricLabel: 'Akurasi: ${(log.accuracy * 100).toStringAsFixed(1)}%',
              status: 'Log-Loss: ${log.logLoss.toStringAsFixed(2)}',
              color: const Color(0xFFF59E0B),
              icon: Icons.alt_route_rounded,
            ),
            _metricMiniCard(
              title: 'Naive Bayes',
              subtitle: 'Screening Kelayakan',
              metricLabel: 'Akurasi: ${(nb.accuracy * 100).toStringAsFixed(1)}%',
              status: 'Gaussian + Laplace',
              color: const Color(0xFF10B981),
              icon: Icons.hub_rounded,
            ),
            _metricMiniCard(
              title: 'Support Vector Machine',
              subtitle: 'Safety & Kelayakan Mobil',
              metricLabel: 'Akurasi: ${(svm.accuracy * 100).toStringAsFixed(1)}%',
              status: '${svm.supportVectorCount} Support Vectors',
              color: const Color(0xFF8B5CF6),
              icon: Icons.shield_outlined,
            ),
          ],
        );
      },
    );
  }

  Widget _metricMiniCard({
    required String title,
    required String subtitle,
    required String metricLabel,
    required String status,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(status, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              const SizedBox(height: 4),
              Text(metricLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: LINEAR REGRESSION
  // ==========================================
  Widget _buildLinearRegressionTab(MlService ml, bool isMobile) {
    final lin = ml.linearRegression;
    final predictedCost = lin.predict([_simKm, _simAge]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoCard(
          title: 'Konsep & Fungsi Linear Regression pada RentDesk',
          content: 'Model ini digunakan untuk memproyeksikan angka kontinu (kontinyu) seperti estimasi biaya perawatan/servis armada berdasarkan variabel kilometer tempuh dan umur unit kendaraan. Menggunakan metode Gradient Descent pada galat kuadrat terkecil (Ordinary Least Squares).',
          color: const Color(0xFF3B82F6),
        ),
        const SizedBox(height: 16),

        // Formula Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Persamaan Garis Regresi Terlatih:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              const SizedBox(height: 4),
              SelectableText(
                lin.getFormulaString(),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Color(0xFF60A5FA), fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _statPill('R² Determinasi', '${(lin.r2Score * 100).toStringAsFixed(2)}%'),
                  const SizedBox(width: 8),
                  _statPill('Bobot Odometer (w1)', lin.weights.isNotEmpty ? lin.weights[0].toStringAsFixed(2) : '-'),
                  const SizedBox(width: 8),
                  _statPill('Bobot Usia (w2)', lin.weights.length > 1 ? lin.weights[1].toStringAsFixed(2) : '-'),
                  const SizedBox(width: 8),
                  _statPill('Bias (b)', lin.bias.toStringAsFixed(2)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Interactive Simulator
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Controls
            Expanded(
              flex: isMobile ? 1 : 6,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.tune_rounded, size: 18, color: AppTheme.primary),
                        SizedBox(width: 8),
                        Text('Simulator Input Prediksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Odometer Saat Ini:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        Text('${_simKm.toInt().toString()} KM', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                      ],
                    ),
                    Slider(
                      value: _simKm,
                      min: 1000,
                      max: 200000,
                      divisions: 199,
                      activeColor: AppTheme.primary,
                      onChanged: (val) => setState(() => _simKm = val),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Usia Kendaraan:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        Text('${_simAge.toInt().toString()} Tahun', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                      ],
                    ),
                    Slider(
                      value: _simAge,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      activeColor: AppTheme.primary,
                      onChanged: (val) => setState(() => _simAge = val),
                    ),
                  ],
                ),
              ),
            ),
            if (!isMobile) const SizedBox(width: 16),
            // Result Display
            Expanded(
              flex: isMobile ? 1 : 5,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('HASIL ESTIMASI BIAYA SERVIS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                    const SizedBox(height: 8),
                    Text(
                      currency.format(predictedCost.clamp(100000.0, 50000000.0)),
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF60A5FA)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Biaya yang disarankan untuk dialokasikan pada unit dengan jarak tempuh ${_simKm.toInt()} km & umur ${_simAge.toInt()} tahun.',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                    const Divider(height: 24, color: AppTheme.border),
                    _specRow('Rekomendasi Anggaran:', 'Sesuai Prediksi Regresi'),
                    const SizedBox(height: 4),
                    _specRow('Status Cadangan Finansial:', predictedCost > 2500000 ? 'Perlu Prioritas Servis Besar' : 'Biaya Rutin Normal'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // TAB 2: LOGISTIC REGRESSION
  // ==========================================
  Widget _buildLogisticRegressionTab(MlService ml, bool isMobile) {
    final log = ml.logisticRegression;
    final features = [_simRentalDays, _simHasPastLate ? 1.0 : 0.0, _simKmPerDay, _simCustomerAge];
    final probLate = log.predictProbability(features);
    final isHighRisk = probLate >= 0.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoCard(
          title: 'Konsep & Fungsi Logistic Regression pada RentDesk',
          content: 'Model ini menghitung probabilitas biner (antara 0% hingga 100%) apakah seorang penyewa berisiko mengembalikan mobil terlambat (Overtime) berdasarkan durasi sewa, riwayat denda sebelumnya, perkiraan rute jarak tempuh, dan usia pelanggan.',
          color: const Color(0xFFF59E0B),
        ),
        const SizedBox(height: 16),

        // Simulator
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: isMobile ? 1 : 6,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person_search_rounded, size: 18, color: Color(0xFFF59E0B)),
                        SizedBox(width: 8),
                        Text('Simulator Profil Transaksi Sewa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Durasi Sewa
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Durasi Sewa:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        Text('${_simRentalDays.toInt()} Hari', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                      ],
                    ),
                    Slider(
                      value: _simRentalDays,
                      min: 1,
                      max: 14,
                      divisions: 13,
                      activeColor: const Color(0xFFF59E0B),
                      onChanged: (v) => setState(() => _simRentalDays = v),
                    ),

                    // Riwayat Telat
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Pernah Ada Riwayat Denda/Overtime?', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      value: _simHasPastLate,
                      activeThumbColor: const Color(0xFFF59E0B),
                      onChanged: (v) => setState(() => _simHasPastLate = v),
                    ),

                    // Estimasi KM/Hari
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Estimasi Rute (KM / Hari):', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        Text('${_simKmPerDay.toInt()} KM/Hari', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                      ],
                    ),
                    Slider(
                      value: _simKmPerDay,
                      min: 20,
                      max: 300,
                      divisions: 28,
                      activeColor: const Color(0xFFF59E0B),
                      onChanged: (v) => setState(() => _simKmPerDay = v),
                    ),

                    // Usia Penyewa
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Usia Penyewa:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        Text('${_simCustomerAge.toInt()} Tahun', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                      ],
                    ),
                    Slider(
                      value: _simCustomerAge,
                      min: 18,
                      max: 65,
                      divisions: 47,
                      activeColor: const Color(0xFFF59E0B),
                      onChanged: (v) => setState(() => _simCustomerAge = v),
                    ),
                  ],
                ),
              ),
            ),
            if (!isMobile) const SizedBox(width: 16),
            Expanded(
              flex: isMobile ? 1 : 5,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: (isHighRisk ? AppTheme.danger : AppTheme.success).withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PROBABILITAS KETERLAMBATAN (SIGMOID)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(probLate * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: isHighRisk ? AppTheme.danger : AppTheme.success,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isHighRisk ? AppTheme.danger : AppTheme.success).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: isHighRisk ? AppTheme.danger : AppTheme.success),
                          ),
                          child: Text(
                            isHighRisk ? 'RISIKO TINGGI TELAT' : 'AMAN (TEPAT WAKTU)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isHighRisk ? AppTheme.danger : AppTheme.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: probLate.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: AppTheme.border,
                        valueColor: AlwaysStoppedAnimation<Color>(isHighRisk ? AppTheme.danger : AppTheme.success),
                      ),
                    ),
                    const Divider(height: 24, color: AppTheme.border),
                    const Text('Rekomendasi Tindakan Kasir:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    const SizedBox(height: 4),
                    Text(
                      isHighRisk
                          ? '• Terapkan jaminan KTP + SIM asli ditahan\n• Minta deposit uang jaminan minimal Rp 500.000\n• Atur pengingat otomatis WhatsApp H-3 jam sebelum jam sewa habis.'
                          : '• Transaksi standar tanpa syarat deposit tambahan\n• Konfirmasi ramah H-1 jam sebelum jadwal pengembalian.',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // TAB 3: NAIVE BAYES
  // ==========================================
  Widget _buildNaiveBayesTab(MlService ml, bool isMobile) {
    final nb = ml.naiveBayes;
    final features = [_simDocCompleteness, _simLocalDomicile, _simJobStatus, _simEmergencyContact];
    final prediction = nb.predict(features);

    Color badgeColor = AppTheme.success;
    if (prediction.bestClass.contains('VERIFIKASI')) {
      badgeColor = AppTheme.warning;
    } else if (prediction.bestClass.contains('TOLAK')) {
      badgeColor = AppTheme.danger;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoCard(
          title: 'Konsep & Fungsi Naive Bayes pada RentDesk',
          content: 'Model ini menerapkan Teorema Bayes P(C|X) = P(X|C)P(C) / P(X) dengan Laplace smoothing untuk memprediksi kelayakan pelanggan baru (mencegah penipuan atau penggelapan mobil rental). Mengkombinasikan probabilitas atribut dokumen, domisili, dan pekerjaan.',
          color: const Color(0xFF10B981),
        ),
        const SizedBox(height: 16),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: isMobile ? 1 : 6,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.verified_user_rounded, size: 18, color: Color(0xFF10B981)),
                        SizedBox(width: 8),
                        Text('Simulator Verifikasi Pelanggan Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Dokumen
                    const Text('Kelengkapan Dokumen Identitas:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<double>(
                      initialValue: _simDocCompleteness,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTheme.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.border)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      dropdownColor: AppTheme.surfaceCard,
                      items: const [
                        DropdownMenuItem(value: 3.0, child: Text('KTP + SIM A Lengkap (Terverifikasi)', style: TextStyle(fontSize: 12, color: AppTheme.textPrimary))),
                        DropdownMenuItem(value: 2.0, child: Text('Hanya KTP (SIM Belum Jelas)', style: TextStyle(fontSize: 12, color: AppTheme.textPrimary))),
                        DropdownMenuItem(value: 1.0, child: Text('Dokumen Kurang / Foto Kabur', style: TextStyle(fontSize: 12, color: AppTheme.textPrimary))),
                      ],
                      onChanged: (v) => setState(() => _simDocCompleteness = v ?? 3.0),
                    ),
                    const SizedBox(height: 12),

                    // Domisili
                    const Text('Domisili Tempat Tinggal:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<double>(
                      initialValue: _simLocalDomicile,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTheme.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.border)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      dropdownColor: AppTheme.surfaceCard,
                      items: const [
                        DropdownMenuItem(value: 1.0, child: Text('Warga Lokal (KTP Sesuai Kota Rental)', style: TextStyle(fontSize: 12, color: AppTheme.textPrimary))),
                        DropdownMenuItem(value: 0.0, child: Text('Wisatawan / Warga Luar Kota', style: TextStyle(fontSize: 12, color: AppTheme.textPrimary))),
                      ],
                      onChanged: (v) => setState(() => _simLocalDomicile = v ?? 1.0),
                    ),
                    const SizedBox(height: 12),

                    // Pekerjaan
                    const Text('Status Pekerjaan:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<double>(
                      initialValue: _simJobStatus,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTheme.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.border)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      dropdownColor: AppTheme.surfaceCard,
                      items: const [
                        DropdownMenuItem(value: 3.0, child: Text('Karyawan Swasta / BUMN / ASN Tetap', style: TextStyle(fontSize: 12, color: AppTheme.textPrimary))),
                        DropdownMenuItem(value: 2.0, child: Text('Wiraswasta / Freelancer', style: TextStyle(fontSize: 12, color: AppTheme.textPrimary))),
                        DropdownMenuItem(value: 1.0, child: Text('Tidak Jelas / Belum Bekerja', style: TextStyle(fontSize: 12, color: AppTheme.textPrimary))),
                      ],
                      onChanged: (v) => setState(() => _simJobStatus = v ?? 3.0),
                    ),
                    const SizedBox(height: 12),

                    // Kontak Darurat
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Kontak Darurat Keluarga Terhubung & Valid?', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      value: _simEmergencyContact == 1.0,
                      activeThumbColor: const Color(0xFF10B981),
                      onChanged: (v) => setState(() => _simEmergencyContact = v ? 1.0 : 0.0),
                    ),
                  ],
                ),
              ),
            ),
            if (!isMobile) const SizedBox(width: 16),
            Expanded(
              flex: isMobile ? 1 : 5,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('HASIL KLASIFIKASI KELAYAKAN (NAIVE BAYES)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: badgeColor),
                      ),
                      child: Text(
                        prediction.bestClass,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: badgeColor),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Distribusi Probabilitas Posterior Tiap Kelas:', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    ...prediction.probabilities.entries.map((entry) {
                      final prob = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(entry.key, style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
                                Text('${(prob * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                              ],
                            ),
                            const SizedBox(height: 3),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: prob.clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: AppTheme.border,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  entry.key.contains('LAYAK') ? AppTheme.success : (entry.key.contains('VERIFIKASI') ? AppTheme.warning : AppTheme.danger),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // TAB 4: SUPPORT VECTOR MACHINE (SVM)
  // ==========================================
  Widget _buildSvmTab(MlService ml, bool isMobile) {
    final svm = ml.svmClassifier;
    final features = [_simKmSinceService, _simDefectCount, _simComplaintScore];
    final prediction = svm.predict(features);

    final isPrima = prediction.isPositive;
    final resultColor = isPrima ? AppTheme.success : AppTheme.danger;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoCard(
          title: 'Konsep & Fungsi SVM (Support Vector Machine) pada RentDesk',
          content: 'Model ini mencari garis pemisah optimal (Hyperplane w · x + b = 0) dengan margin selebar mungkin (2/||w||) menggunakan Hinge Loss. Berfungsi untuk menentukan kelayakan keselamatan mobil secara ketat: apakah armada PRIMA (aman disewa) atau KRITIS (wajib karantina / masuk bengkel segera).',
          color: const Color(0xFF8B5CF6),
        ),
        const SizedBox(height: 16),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: isMobile ? 1 : 6,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.health_and_safety_rounded, size: 18, color: Color(0xFF8B5CF6)),
                        SizedBox(width: 8),
                        Text('Simulator Kondisi Armada Mobil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // KM Sejak Servis
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('KM Sejak Servis Terakhir:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        Text('${_simKmSinceService.toInt()} KM', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))),
                      ],
                    ),
                    Slider(
                      value: _simKmSinceService,
                      min: 500,
                      max: 15000,
                      divisions: 29,
                      activeColor: const Color(0xFF8B5CF6),
                      onChanged: (v) => setState(() => _simKmSinceService = v),
                    ),

                    // Jumlah Kerusakan Bodi
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Jumlah Titik Cacat/Baret Bodi:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        Text('${_simDefectCount.toInt()} Titik', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))),
                      ],
                    ),
                    Slider(
                      value: _simDefectCount,
                      min: 0,
                      max: 10,
                      divisions: 10,
                      activeColor: const Color(0xFF8B5CF6),
                      onChanged: (v) => setState(() => _simDefectCount = v),
                    ),

                    // Skor Keluhan Mesin / Getaran
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Skor Keluhan Teknis Mekanik (1-10):', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        Text('${_simComplaintScore.toInt()} / 10', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))),
                      ],
                    ),
                    Slider(
                      value: _simComplaintScore,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      activeColor: const Color(0xFF8B5CF6),
                      onChanged: (v) => setState(() => _simComplaintScore = v),
                    ),
                  ],
                ),
              ),
            ),
            if (!isMobile) const SizedBox(width: 16),
            Expanded(
              flex: isMobile ? 1 : 5,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: resultColor.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('KEPUTUSAN HYPERPLANE SVM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(isPrima ? Icons.check_circle_rounded : Icons.warning_rounded, color: resultColor, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          prediction.predictedLabel,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: resultColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _specRow('Nilai Keputusan (w · x + b):', prediction.decisionValue.toStringAsFixed(3)),
                    const SizedBox(height: 4),
                    _specRow('Jarak Geometris ke Hyperplane:', '${prediction.geometricDistance.abs().toStringAsFixed(3)} unit'),
                    const SizedBox(height: 4),
                    _specRow('Lebar Margin Hyperplane:', svm.marginWidth.toStringAsFixed(2)),
                    const SizedBox(height: 4),
                    _specRow('Jumlah Support Vector Model:', '${svm.supportVectorCount} sampel'),
                    const Divider(height: 24, color: AppTheme.border),
                    Text(
                      isPrima
                          ? 'Unit berada di sisi positif hyperplane (+1). Mobil aman untuk disewakan ke konsumen.'
                          : 'Unit berada di sisi negatif hyperplane (-1). Sistem menyarankan untuk mengunci unit (karantina) dan segera dijadwalkan servis bengkel.',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // HELPER WIDGETS
  // ==========================================
  Widget _infoCard({required String title, required String content, required Color color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: color, size: 18),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          Text(content, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4)),
        ],
      ),
    );
  }

  Widget _statPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
          Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _specRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
      ],
    );
  }
}
