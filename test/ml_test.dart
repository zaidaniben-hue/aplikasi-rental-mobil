import 'package:flutter_test/flutter_test.dart';
import 'package:rentdesk/services/machine_learning/ml_service.dart';

void main() {
  test('Machine Learning Suite Tests (Linear, Logistic, Naive Bayes, SVM)', () {
    final ml = MlService();
    expect(ml.isReady, isTrue);

    // 1. Linear Regression
    final linPred = ml.linearRegression.predict([45000, 3]);
    expect(linPred, isPositive);
    expect(ml.linearRegression.r2Score, greaterThan(0.8));

    // 2. Logistic Regression
    final logProb = ml.logisticRegression.predictProbability([5, 1, 160, 23]);
    expect(logProb, inInclusiveRange(0.0, 1.0));
    expect(ml.logisticRegression.accuracy, greaterThan(0.8));

    // 3. Naive Bayes
    final nbPred = ml.naiveBayes.predict([3.0, 1.0, 3.0, 1.0]);
    expect(nbPred.bestClass, equals('LAYAK SEWA (Aman)'));

    // 4. SVM Classifier
    final svmPred = ml.svmClassifier.predict([8500, 3, 6]);
    expect(svmPred.predictedLabel, isNotEmpty);
    expect(ml.svmClassifier.marginWidth, isPositive);
  });
}
