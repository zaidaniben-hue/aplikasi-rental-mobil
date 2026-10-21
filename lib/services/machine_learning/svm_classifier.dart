import 'dart:math' as math;

/// Model Support Vector Machine (Linear SVM dengan Soft-Margin & Sub-Gradient Descent)
/// Formula Hyperplane: w · x + b = 0
/// Margin: 2 / ||w||
/// Hinge Loss: L = max(0, 1 - y_i * (w · x_i + b))
class SvmClassifierModel {
  List<double> weights = [];
  double bias = 0.0;
  List<String> featureNames = [];
  String positiveLabel = 'Layak Jalan (Prima)';
  String negativeLabel = 'Kritis (Masuk Bengkel)';
  
  double accuracy = 0.0;
  int supportVectorCount = 0;
  double marginWidth = 0.0;
  bool isTrained = false;

  List<double> minX = [];
  List<double> maxX = [];

  SvmClassifierModel({
    required this.featureNames,
    required this.positiveLabel,
    required this.negativeLabel,
  });

  /// Melatih model SVM menggunakan Subgradient Descent pada Soft-Margin Hinge Loss
  void train({
    required List<List<double>> X,
    required List<int> yLabels, // +1 atau -1
    double cParam = 1.0, // Parameter penalti margin soft C
    double learningRate = 0.01,
    int epochs = 1500,
  }) {
    if (X.isEmpty || yLabels.isEmpty || X.length != yLabels.length) return;

    final nSamples = X.length;
    final nFeatures = X[0].length;

    weights = List<double>.filled(nFeatures, 0.0);
    bias = 0.0;

    // Normalisasi fitur
    minX = List<double>.filled(nFeatures, double.infinity);
    maxX = List<double>.filled(nFeatures, -double.infinity);

    for (var row in X) {
      for (int j = 0; j < nFeatures; j++) {
        if (row[j] < minX[j]) minX[j] = row[j];
        if (row[j] > maxX[j]) maxX[j] = row[j];
      }
    }

    List<List<double>> normX = [];
    for (var row in X) {
      List<double> normRow = [];
      for (int j = 0; j < nFeatures; j++) {
        final range = maxX[j] - minX[j];
        normRow.add(range == 0 ? 0.0 : (row[j] - minX[j]) / range);
      }
      normX.add(normRow);
    }

    // Subgradient Descent
    for (int epoch = 1; epoch <= epochs; epoch++) {
      // Step size decay
      final lr = learningRate / math.sqrt(epoch);

      for (int i = 0; i < nSamples; i++) {
        final yi = yLabels[i]; // +1 or -1
        double dotProduct = bias;
        for (int j = 0; j < nFeatures; j++) {
          dotProduct += weights[j] * normX[i][j];
        }

        final margin = yi * dotProduct;

        if (margin < 1.0) {
          // Terjadi pelanggaran margin (Hinge Loss > 0)
          for (int j = 0; j < nFeatures; j++) {
            weights[j] = weights[j] - lr * (weights[j] - cParam * yi * normX[i][j]);
          }
          bias += lr * (cParam * yi);
        } else {
          // Titik berada di luar margin
          for (int j = 0; j < nFeatures; j++) {
            weights[j] = weights[j] - lr * weights[j];
          }
        }
      }
    }

    // Hitung Support Vectors, Margin Width, dan Akurasi
    double normW = 0.0;
    for (var w in weights) {
      normW += w * w;
    }
    normW = math.sqrt(normW);
    marginWidth = normW == 0 ? 0.0 : (2.0 / normW);

    int svCount = 0;
    int correct = 0;

    for (int i = 0; i < nSamples; i++) {
      final yi = yLabels[i];
      final res = predict(X[i]);
      final predY = res.predictedLabel == positiveLabel ? 1 : -1;

      if (predY == yi) correct++;

      // Cek apakah sample adalah support vector (jarak margin <= 1)
      double dot = bias;
      for (int j = 0; j < nFeatures; j++) {
        final range = maxX[j] - minX[j];
        final nv = range == 0 ? 0.0 : (X[i][j] - minX[j]) / range;
        dot += weights[j] * nv;
      }
      if (yi * dot <= 1.05) {
        svCount++;
      }
    }

    accuracy = correct / nSamples;
    supportVectorCount = svCount;
    isTrained = true;
  }

  /// Prediksi keputusan SVM, jarak ke hyperplane, dan margin status
  SvmPrediction predict(List<double> features) {
    if (features.length != weights.length) {
      throw ArgumentError('Jumlah fitur (${features.length}) tidak sesuai model (${weights.length})');
    }

    double dotProduct = bias;
    for (int j = 0; j < features.length; j++) {
      final range = maxX[j] - minX[j];
      final normVal = range == 0 ? 0.0 : (features[j] - minX[j]) / range;
      dotProduct += weights[j] * normVal;
    }

    double normW = 0.0;
    for (var w in weights) {
      normW += w * w;
    }
    normW = math.sqrt(normW);

    // Jarak geometris bertanda ke hyperplane: d = (w · x + b) / ||w||
    final geometricDistance = normW == 0 ? dotProduct : (dotProduct / normW);
    final isPositive = dotProduct >= 0;

    return SvmPrediction(
      decisionValue: dotProduct,
      geometricDistance: geometricDistance,
      predictedLabel: isPositive ? positiveLabel : negativeLabel,
      isPositive: isPositive,
    );
  }
}

class SvmPrediction {
  final double decisionValue; // w · x + b
  final double geometricDistance; // jarak ke pemisah hyperplane
  final String predictedLabel;
  final bool isPositive;

  SvmPrediction({
    required this.decisionValue,
    required this.geometricDistance,
    required this.predictedLabel,
    required this.isPositive,
  });
}
