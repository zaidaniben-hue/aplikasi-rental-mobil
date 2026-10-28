import '../../models/models.dart';
import 'linear_regression.dart';
import 'logistic_regression.dart';
import 'naive_bayes.dart';
import 'svm_classifier.dart';

export 'linear_regression.dart';
export 'logistic_regression.dart';
export 'naive_bayes.dart';
export 'svm_classifier.dart';

/// Service Terpusat untuk Orkestrasi Seluruh Algoritma Machine Learning di RentDesk
class MlService {
  static final MlService _instance = MlService._internal();
  factory MlService() => _instance;
  MlService._internal() {
    initAndTrainAllModels();
  }

  // Model 1: Linear Regression (Prediksi Biaya Perawatan & Depresiasi)
  late LinearRegressionModel linearRegression;

  // Model 2: Logistic Regression (Prediksi Risiko Keterlambatan Pengembalian Sewa)
  late LogisticRegressionModel logisticRegression;

  // Model 3: Naive Bayes (Screening Kelayakan Pelanggan Baru & Anti-Blacklist)
  late NaiveBayesModel naiveBayes;

  // Model 4: Support Vector Machine (Klasifikasi Tingkat Kesehatan & Urgensi Servis)
  late SvmClassifierModel svmClassifier;

  bool isReady = false;
  DateTime? lastTrainedTime;

  /// Inisialisasi dan training awal seluruh model menggunakan benchmark data rental
  void initAndTrainAllModels({List<Vehicle>? vehicles, List<Rental>? rentals}) {
    // 1. Inisialisasi & Training Linear Regression
    linearRegression = LinearRegressionModel(
      featureNames: ['Odometer (KM)', 'Usia Mobil (Tahun)'],
      targetName: 'Estimasi Biaya Servis (Rp)',
    );

    // Dataset historis biaya servis berdasarkan KM dan usia armada
    List<List<double>> linX = [
      [5000, 1],
      [12000, 1],
      [22000, 2],
      [35000, 2],
      [48000, 3],
      [60000, 3],
      [75000, 4],
      [90000, 5],
      [110000, 6],
      [135000, 7],
      [160000, 8],
    ];
    List<double> linY = [
      350000,
      600000,
      850000,
      1200000,
      1650000,
      2100000,
      2700000,
      3400000,
      4200000,
      5100000,
      6200000,
    ];

    // Bila ada data aktual kendaraan, tambahkan ke pelatihan
    if (vehicles != null && vehicles.isNotEmpty) {
      final currentYear = DateTime.now().year;
      for (var v in vehicles) {
        final age = (currentYear - v.yearMade).toDouble().clamp(1.0, 15.0);
        final km = v.odometerCurrent.toDouble();
        // Nilai acuan servis aktual rental
        final estimatedCost = (km * 35.0) + (age * 200000.0);
        linX.add([km, age]);
        linY.add(estimatedCost);
      }
    }

    linearRegression.train(X: linX, y: linY);

    // 2. Inisialisasi & Training Logistic Regression
    // Fitur: [Durasi Sewa (Hari), Riwayat Telat Sebelumnya (0/1), Rasio KM Sewa Harian, Usia Penyewa]
    logisticRegression = LogisticRegressionModel(
      featureNames: ['Durasi Sewa (Hari)', 'Pernah Telat (0/1)', 'Estimasi KM/Hari', 'Usia Penyewa'],
      targetLabel: 'Potensi Telat (Overtime)',
    );

    List<List<double>> logX = [
      [1, 0, 40, 35],  // Tepat waktu (0)
      [2, 0, 60, 28],  // Tepat waktu (0)
      [1, 0, 90, 42],  // Tepat waktu (0)
      [3, 0, 50, 30],  // Tepat waktu (0)
      [4, 1, 180, 22], // Terlambat (1)
      [7, 1, 220, 24], // Terlambat (1)
      [2, 1, 150, 21], // Terlambat (1)
      [5, 0, 75, 45],  // Tepat waktu (0)
      [6, 1, 200, 23], // Terlambat (1)
      [1, 0, 30, 50],  // Tepat waktu (0)
      [10, 1, 250, 26],// Terlambat (1)
      [3, 0, 80, 38],  // Tepat waktu (0)
    ];
    List<int> logY = [0, 0, 0, 0, 1, 1, 1, 0, 1, 0, 1, 0];

    logisticRegression.train(X: logX, y: logY);

    // 3. Inisialisasi & Training Naive Bayes (Screening Calon Pelanggan)
    // Fitur: [Kelengkapan Dokumen (1-3), Domisili Lokal (0/1), Status Pekerjaan (1-3), Kontak Darurat (0/1)]
    // Kelas: 'LAYAK SEWA (Aman)', 'VERIFIKASI KETAT', 'TOLAK / BLACKLIST'
    naiveBayes = NaiveBayesModel(
      classLabels: ['LAYAK SEWA (Aman)', 'VERIFIKASI KETAT', 'TOLAK / BLACKLIST'],
      featureNames: ['Dokumen (KTP+SIM)', 'Domisili Lokal', 'Pekerjaan Tetap', 'Kontak Darurat'],
    );

    List<List<double>> nbX = [
      [3.0, 1.0, 3.0, 1.0], // Lengkap, lokal, tetap, ada darurat -> Layak
      [3.0, 1.0, 2.0, 1.0], // Layak
      [3.0, 0.0, 3.0, 1.0], // Layak
      [2.0, 1.0, 2.0, 1.0], // Verifikasi
      [2.0, 0.0, 2.0, 0.0], // Verifikasi
      [2.0, 1.0, 1.0, 0.0], // Verifikasi
      [1.0, 0.0, 1.0, 0.0], // Tolak
      [1.0, 0.0, 1.0, 1.0], // Tolak
      [1.0, 1.0, 0.0, 0.0], // Tolak
      [3.0, 1.0, 3.0, 1.0], // Layak
    ];
    List<String> nbY = [
      'LAYAK SEWA (Aman)',
      'LAYAK SEWA (Aman)',
      'LAYAK SEWA (Aman)',
      'VERIFIKASI KETAT',
      'VERIFIKASI KETAT',
      'VERIFIKASI KETAT',
      'TOLAK / BLACKLIST',
      'TOLAK / BLACKLIST',
      'TOLAK / BLACKLIST',
      'LAYAK SEWA (Aman)',
    ];

    naiveBayes.train(X: nbX, y: nbY);

    // 4. Inisialisasi & Training SVM (Kelayakan Armada / Prima vs Kritis Bengkel)
    // Fitur: [KM Sejak Servis Terakhir, Jumlah Kerusakan Bodi, Rasio Utilisasi %]
    // +1 = PRIMA (Aman Jalan), -1 = KRITIS (Masuk Bengkel)
    svmClassifier = SvmClassifierModel(
      featureNames: ['KM Sejak Servis Terakhir', 'Jumlah Titik Cacat Bodi', 'Skor Keluhan Teknis (1-10)'],
      positiveLabel: 'PRIMA (Aman Jalan)',
      negativeLabel: 'KRITIS (Masuk Bengkel)',
    );

    List<List<double>> svmX = [
      [1500, 0, 1], // +1
      [3000, 1, 2], // +1
      [4500, 1, 2], // +1
      [6000, 2, 3], // +1
      [9500, 4, 7], // -1
      [12000, 5, 8], // -1
      [14000, 3, 9], // -1
      [2000, 0, 1], // +1
      [10500, 6, 8], // -1
      [5000, 2, 3], // +1
    ];
    List<int> svmY = [1, 1, 1, 1, -1, -1, -1, 1, -1, 1];

    svmClassifier.train(X: svmX, yLabels: svmY);

    isReady = true;
    lastTrainedTime = DateTime.now();
  }

  // --- 1. Linear Regression Helper ---
  double predictMaintenanceCost({required double odometerKm, required double vehicleAgeYears}) {
    if (!isReady || !linearRegression.isTrained) return 750000.0;
    try {
      final pred = linearRegression.predict([odometerKm, vehicleAgeYears]);
      return pred < 250000 ? 250000 : pred;
    } catch (_) {
      return 750000.0;
    }
  }

  // --- 2. Logistic Regression Helper ---
  double predictRentalLateProbability({
    required double durationDays,
    required bool hasPastLate,
    required double kmPerDay,
    required double customerAge,
  }) {
    if (!isReady || !logisticRegression.isTrained) return 0.2;
    try {
      return logisticRegression.predictProbability([
        durationDays.clamp(1.0, 30.0),
        hasPastLate ? 1.0 : 0.0,
        kmPerDay.clamp(10.0, 500.0),
        customerAge.clamp(18.0, 75.0),
      ]);
    } catch (_) {
      return 0.2;
    }
  }

  // --- 3. Naive Bayes Helper ---
  NaiveBayesPrediction screenCustomerEligibility({
    required double docScore,
    required bool isLocalDomicile,
    required double jobStatusScore,
    required bool hasEmergencyContact,
  }) {
    if (!isReady || !naiveBayes.isTrained) {
      return NaiveBayesPrediction(
        bestClass: 'LAYAK SEWA (Aman)',
        probabilities: {'LAYAK SEWA (Aman)': 0.85, 'VERIFIKASI KETAT': 0.12, 'TOLAK / BLACKLIST': 0.03},
      );
    }
    try {
      return naiveBayes.predict([
        docScore.clamp(1.0, 3.0),
        isLocalDomicile ? 1.0 : 0.0,
        jobStatusScore.clamp(1.0, 3.0),
        hasEmergencyContact ? 1.0 : 0.0,
      ]);
    } catch (_) {
      return NaiveBayesPrediction(
        bestClass: 'LAYAK SEWA (Aman)',
        probabilities: {'LAYAK SEWA (Aman)': 0.85, 'VERIFIKASI KETAT': 0.12, 'TOLAK / BLACKLIST': 0.03},
      );
    }
  }

  // --- 4. Support Vector Machine Helper ---
  SvmPrediction evaluateFleetSafety({
    required double kmSinceLastService,
    required double defectCount,
    required double complaintScore,
  }) {
    if (!isReady || !svmClassifier.isTrained) {
      return SvmPrediction(
        decisionValue: 1.0,
        geometricDistance: 0.8,
        predictedLabel: 'PRIMA (Aman Jalan)',
        isPositive: true,
      );
    }
    try {
      return svmClassifier.predict([
        kmSinceLastService.clamp(0.0, 50000.0),
        defectCount.clamp(0.0, 20.0),
        complaintScore.clamp(1.0, 10.0),
      ]);
    } catch (_) {
      return SvmPrediction(
        decisionValue: 1.0,
        geometricDistance: 0.8,
        predictedLabel: 'PRIMA (Aman Jalan)',
        isPositive: true,
      );
    }
  }
}
