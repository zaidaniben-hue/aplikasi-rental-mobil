import 'dart:math' as math;

/// Model Regresi Logistik (Logistic Regression) untuk Klasifikasi Biner Probabilistik
/// Formula Logit: z = w1*x1 + w2*x2 + ... + wn*xn + b
/// Sigmoid: p = 1 / (1 + e^(-z))
class LogisticRegressionModel {
  List<double> weights = [];
  double bias = 0.0;
  List<String> featureNames = [];
  String targetLabel = '';
  double accuracy = 0.0;
  double logLoss = 0.0;
  bool isTrained = false;

  // Nilai scaling untuk normalisasi
  List<double> minX = [];
  List<double> maxX = [];

  LogisticRegressionModel({
    required this.featureNames,
    required this.targetLabel,
  });

  /// Fungsi Aktivasi Sigmoid dengan proteksi overflow numerik
  static double sigmoid(double z) {
    if (z > 30) return 1.0;
    if (z < -30) return 0.0;
    return 1.0 / (1.0 + math.exp(-z));
  }

  /// Melatih model regresi logistik dengan Gradient Descent
  void train({
    required List<List<double>> X,
    required List<int> y,
    double learningRate = 0.1,
    int epochs = 1200,
  }) {
    if (X.isEmpty || y.isEmpty || X.length != y.length) return;

    final nSamples = X.length;
    final nFeatures = X[0].length;

    weights = List<double>.filled(nFeatures, 0.0);
    bias = 0.0;

    // Hitung Min-Max untuk scaling
    minX = List<double>.filled(nFeatures, double.infinity);
    maxX = List<double>.filled(nFeatures, -double.infinity);

    for (var row in X) {
      for (int j = 0; j < nFeatures; j++) {
        if (row[j] < minX[j]) minX[j] = row[j];
        if (row[j] > maxX[j]) maxX[j] = row[j];
      }
    }

    // Normalisasi input
    List<List<double>> normX = [];
    for (var row in X) {
      List<double> normRow = [];
      for (int j = 0; j < nFeatures; j++) {
        final range = maxX[j] - minX[j];
        normRow.add(range == 0 ? 0.0 : (row[j] - minX[j]) / range);
      }
      normX.add(normRow);
    }

    // Gradient Descent pada Log-Loss
    for (int epoch = 0; epoch < epochs; epoch++) {
      List<double> dw = List<double>.filled(nFeatures, 0.0);
      double db = 0.0;

      for (int i = 0; i < nSamples; i++) {
        double z = bias;
        for (int j = 0; j < nFeatures; j++) {
          z += weights[j] * normX[i][j];
        }
        final p = sigmoid(z);
        final error = p - y[i];

        for (int j = 0; j < nFeatures; j++) {
          dw[j] += error * normX[i][j];
        }
        db += error;
      }

      for (int j = 0; j < nFeatures; j++) {
        weights[j] -= (learningRate / nSamples) * dw[j];
      }
      bias -= (learningRate / nSamples) * db;
    }

    // Evaluasi Akurasi dan Log-Loss
    int correct = 0;
    double lossSum = 0.0;
    for (int i = 0; i < nSamples; i++) {
      final prob = predictProbability(X[i]);
      final predClass = prob >= 0.5 ? 1 : 0;
      if (predClass == y[i]) correct++;

      // Log-loss
      final eps = 1e-15;
      final clampedP = prob.clamp(eps, 1.0 - eps);
      lossSum += -(y[i] * math.log(clampedP) + (1 - y[i]) * math.log(1 - clampedP));
    }

    accuracy = correct / nSamples;
    logLoss = lossSum / nSamples;
    isTrained = true;
  }

  /// Prediksi probabilitas kelas 1 (0.0 sampai 1.0)
  double predictProbability(List<double> features) {
    if (features.length != weights.length) {
      throw ArgumentError('Jumlah fitur (${features.length}) tidak sesuai model (${weights.length})');
    }
    double z = bias;
    for (int j = 0; j < features.length; j++) {
      final range = maxX[j] - minX[j];
      final normVal = range == 0 ? 0.0 : (features[j] - minX[j]) / range;
      z += weights[j] * normVal;
    }
    return sigmoid(z);
  }

  /// Prediksi kelas (0 atau 1) dengan threshold (default 0.5)
  int predictClass(List<double> features, {double threshold = 0.5}) {
    return predictProbability(features) >= threshold ? 1 : 0;
  }

  String getFormulaString() {
    if (!isTrained) return 'Model belum dilatih';
    return 'P(y=1) = 1 / (1 + e^-(z))\ndi mana z = w·x + b (${weights.length} bobot fitur)';
  }
}
