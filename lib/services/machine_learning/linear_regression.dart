import 'dart:math' as math;

/// Model Regresi Linear Berganda / Sederhana (Ordinary Least Squares / Gradient Descent)
/// Formula: y = w1*x1 + w2*x2 + ... + wn*xn + b
class LinearRegressionModel {
  List<double> weights = [];
  double bias = 0.0;
  List<String> featureNames = [];
  String targetName = '';
  double r2Score = 0.0;
  double meanSquaredError = 0.0;
  bool isTrained = false;

  LinearRegressionModel({
    required this.featureNames,
    required this.targetName,
  });

  /// Melatih model menggunakan Gradient Descent dengan Normalisasi Min-Max
  void train({
    required List<List<double>> X,
    required List<double> y,
    double learningRate = 0.01,
    int epochs = 1000,
  }) {
    if (X.isEmpty || y.isEmpty || X.length != y.length) return;

    final nSamples = X.length;
    final nFeatures = X[0].length;

    weights = List<double>.filled(nFeatures, 0.0);
    bias = 0.0;

    // Normalisasi fitur untuk stabilitas numerik
    final minX = List<double>.filled(nFeatures, double.infinity);
    final maxX = List<double>.filled(nFeatures, -double.infinity);

    for (var row in X) {
      for (int j = 0; j < nFeatures; j++) {
        if (row[j] < minX[j]) minX[j] = row[j];
        if (row[j] > maxX[j]) maxX[j] = row[j];
      }
    }

    List<List<double>> normalizedX = [];
    for (var row in X) {
      List<double> normRow = [];
      for (int j = 0; j < nFeatures; j++) {
        final range = (maxX[j] - minX[j]);
        normRow.add(range == 0 ? 0.0 : (row[j] - minX[j]) / range);
      }
      normalizedX.add(normRow);
    }

    // Normalisasi target y
    double minY = y.reduce(math.min);
    double maxY = y.reduce(math.max);
    final rangeY = (maxY - minY) == 0 ? 1.0 : (maxY - minY);
    List<double> normalizedY = y.map((val) => (val - minY) / rangeY).toList();

    // Gradient Descent
    List<double> wNorm = List<double>.filled(nFeatures, 0.0);
    double bNorm = 0.0;

    for (int epoch = 0; epoch < epochs; epoch++) {
      List<double> dw = List<double>.filled(nFeatures, 0.0);
      double db = 0.0;

      for (int i = 0; i < nSamples; i++) {
        double yPred = bNorm;
        for (int j = 0; j < nFeatures; j++) {
          yPred += wNorm[j] * normalizedX[i][j];
        }
        final error = yPred - normalizedY[i];

        for (int j = 0; j < nFeatures; j++) {
          dw[j] += (2.0 / nSamples) * error * normalizedX[i][j];
        }
        db += (2.0 / nSamples) * error;
      }

      for (int j = 0; j < nFeatures; j++) {
        wNorm[j] -= learningRate * dw[j];
      }
      bNorm -= learningRate * db;
    }

    // Denormalisasi weights dan bias ke skala asli
    for (int j = 0; j < nFeatures; j++) {
      final rangeX = (maxX[j] - minX[j]) == 0 ? 1.0 : (maxX[j] - minX[j]);
      weights[j] = wNorm[j] * (rangeY / rangeX);
    }

    double biasCorrection = 0.0;
    for (int j = 0; j < nFeatures; j++) {
      final rangeX = (maxX[j] - minX[j]) == 0 ? 1.0 : (maxX[j] - minX[j]);
      biasCorrection += wNorm[j] * minX[j] * (rangeY / rangeX);
    }
    bias = (bNorm * rangeY) + minY - biasCorrection;

    // Evaluasi R^2 dan MSE
    double ssTot = 0.0;
    double ssRes = 0.0;
    double meanY = y.reduce((a, b) => a + b) / nSamples;

    for (int i = 0; i < nSamples; i++) {
      final pred = predict(X[i]);
      ssRes += math.pow(y[i] - pred, 2);
      ssTot += math.pow(y[i] - meanY, 2);
    }

    meanSquaredError = ssRes / nSamples;
    r2Score = ssTot == 0 ? 1.0 : math.max(0.0, 1.0 - (ssRes / ssTot));
    isTrained = true;
  }

  /// Prediksi nilai target berdasarkan fitur input
  double predict(List<double> features) {
    if (features.length != weights.length) {
      throw ArgumentError('Jumlah fitur (${features.length}) tidak sesuai dengan model (${weights.length})');
    }
    double result = bias;
    for (int i = 0; i < features.length; i++) {
      result += weights[i] * features[i];
    }
    return result;
  }

  /// Penjelasan rumus matematika dalam format string
  String getFormulaString() {
    if (!isTrained) return 'Model belum dilatih';
    final terms = <String>[];
    for (int i = 0; i < weights.length; i++) {
      final name = i < featureNames.length ? featureNames[i] : 'X$i';
      terms.add('(${weights[i].toStringAsFixed(2)} × $name)');
    }
    return '$targetName = ${terms.join(" + ")} + ${bias.toStringAsFixed(2)}';
  }
}
