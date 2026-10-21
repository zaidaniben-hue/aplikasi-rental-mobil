import 'dart:math' as math;

/// Model Klasifikasi Naive Bayes (Gaussian & Categorical Likelihood dengan Laplace Smoothing)
/// Formula Teorema Bayes: P(C|X) = [P(X|C) * P(C)] / P(X)
class NaiveBayesModel {
  final List<String> classLabels;
  final List<String> featureNames;
  
  Map<String, double> classPriors = {};
  // Mean dan Variance untuk setiap kelas dan fitur kontinu
  Map<String, List<double>> means = {};
  Map<String, List<double>> variances = {};
  
  double accuracy = 0.0;
  bool isTrained = false;

  NaiveBayesModel({
    required this.classLabels,
    required this.featureNames,
  });

  /// Melatih model Gaussian Naive Bayes
  void train({
    required List<List<double>> X,
    required List<String> y,
  }) {
    if (X.isEmpty || y.isEmpty || X.length != y.length) return;

    final nSamples = X.length;
    final nFeatures = X[0].length;

    // 1. Hitung Prior P(C)
    final classCounts = <String, int>{};
    for (var c in classLabels) {
      classCounts[c] = 0;
    }
    for (var label in y) {
      classCounts[label] = (classCounts[label] ?? 0) + 1;
    }

    classPriors.clear();
    for (var entry in classCounts.entries) {
      // Laplace smoothing untuk prior
      classPriors[entry.key] = (entry.value + 1) / (nSamples + classLabels.length);
    }

    // 2. Hitung Mean & Variance per kelas
    means.clear();
    variances.clear();

    for (var c in classLabels) {
      final classRows = <List<double>>[];
      for (int i = 0; i < nSamples; i++) {
        if (y[i] == c) {
          classRows.add(X[i]);
        }
      }

      final cCount = classRows.length;
      if (cCount == 0) {
        means[c] = List<double>.filled(nFeatures, 0.0);
        variances[c] = List<double>.filled(nFeatures, 1.0);
        continue;
      }

      // Hitung mean
      List<double> cMeans = List<double>.filled(nFeatures, 0.0);
      for (var row in classRows) {
        for (int j = 0; j < nFeatures; j++) {
          cMeans[j] += row[j];
        }
      }
      for (int j = 0; j < nFeatures; j++) {
        cMeans[j] /= cCount;
      }
      means[c] = cMeans;

      // Hitung variance dengan epsilon smoothing
      List<double> cVars = List<double>.filled(nFeatures, 0.0);
      for (var row in classRows) {
        for (int j = 0; j < nFeatures; j++) {
          cVars[j] += math.pow(row[j] - cMeans[j], 2);
        }
      }
      for (int j = 0; j < nFeatures; j++) {
        cVars[j] = (cVars[j] / math.max(1, cCount)) + 1e-4; // epsilon smoothing
      }
      variances[c] = cVars;
    }

    // 3. Evaluasi Akurasi
    int correct = 0;
    for (int i = 0; i < nSamples; i++) {
      final pred = predict(X[i]).bestClass;
      if (pred == y[i]) correct++;
    }
    accuracy = correct / nSamples;
    isTrained = true;
  }

  /// Menghitung Gaussian Likelihood: P(x_j | C) = 1/sqrt(2*pi*var) * exp(-(x - mean)^2 / (2*var))
  double _gaussianProbability(double x, double mean, double variance) {
    final exponent = math.exp(-math.pow(x - mean, 2) / (2.0 * variance));
    return (1.0 / (math.sqrt(2.0 * math.pi * variance))) * exponent;
  }

  /// Prediksi kelas dan probabilitas posterior
  NaiveBayesPrediction predict(List<double> features) {
    if (features.length != featureNames.length) {
      throw ArgumentError('Jumlah fitur (${features.length}) tidak sesuai model (${featureNames.length})');
    }

    Map<String, double> logPosteriors = {};

    for (var c in classLabels) {
      final prior = classPriors[c] ?? (1.0 / classLabels.length);
      double logLikelihoodSum = math.log(prior);

      final cMeans = means[c] ?? List<double>.filled(features.length, 0.0);
      final cVars = variances[c] ?? List<double>.filled(features.length, 1.0);

      for (int j = 0; j < features.length; j++) {
        final prob = _gaussianProbability(features[j], cMeans[j], cVars[j]);
        logLikelihoodSum += math.log(math.max(1e-12, prob));
      }

      logPosteriors[c] = logLikelihoodSum;
    }

    // Normalisasi log posteriors ke softmax probabilities
    final maxLog = logPosteriors.values.reduce(math.max);
    Map<String, double> unnormalized = {};
    double sumExp = 0.0;

    for (var entry in logPosteriors.entries) {
      final expVal = math.exp(entry.value - maxLog);
      unnormalized[entry.key] = expVal;
      sumExp += expVal;
    }

    Map<String, double> normalizedProbabilities = {};
    String bestClass = classLabels.first;
    double highestProb = -1.0;

    for (var entry in unnormalized.entries) {
      final prob = sumExp == 0 ? 0.0 : entry.value / sumExp;
      normalizedProbabilities[entry.key] = prob;
      if (prob > highestProb) {
        highestProb = prob;
        bestClass = entry.key;
      }
    }

    return NaiveBayesPrediction(
      bestClass: bestClass,
      probabilities: normalizedProbabilities,
    );
  }
}

class NaiveBayesPrediction {
  final String bestClass;
  final Map<String, double> probabilities;

  NaiveBayesPrediction({
    required this.bestClass,
    required this.probabilities,
  });
}
