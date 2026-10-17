import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:predigeo/domain/entities/measurement_enums.dart';
import 'package:predigeo/domain/usecases/evaluation/precision_analyzer.dart';

void main() {
  group('PrecisionAnalyzer - Error Absoluto y Porcentual', () {
    test('error absoluto: measured=150, reference=140 → error=10', () {
      final pair = EvaluationPair(
        measuredValue: 150.0,
        referenceValue: 140.0,
        category: MeasurementCategory.ruralOpen,
        mode: MeasurementMode.offline,
      );

      expect(pair.absoluteError, equals(10.0));
    });

    test('error absoluto con valor medido menor que referencia', () {
      final pair = EvaluationPair(
        measuredValue: 130.0,
        referenceValue: 140.0,
        category: MeasurementCategory.ruralOpen,
        mode: MeasurementMode.offline,
      );

      expect(pair.absoluteError, equals(10.0));
    });

    test('error porcentual: measured=150, reference=140 → 7.14%', () {
      final pair = EvaluationPair(
        measuredValue: 150.0,
        referenceValue: 140.0,
        category: MeasurementCategory.ruralOpen,
        mode: MeasurementMode.offline,
      );

      expect(pair.percentError, closeTo(7.14, 0.01));
    });

    test('error porcentual con referencia cero retorna 0', () {
      final pair = EvaluationPair(
        measuredValue: 150.0,
        referenceValue: 0.0,
        category: MeasurementCategory.ruralOpen,
        mode: MeasurementMode.offline,
      );

      expect(pair.percentError, equals(0.0));
    });
  });

  group('PrecisionAnalyzer - analyze()', () {
    late PrecisionAnalyzer analyzer;

    setUp(() {
      analyzer = const PrecisionAnalyzer();
    });

    test('RMSE: errores [2, 4, 6] → sqrt(56/3) ≈ 4.32', () {
      final pairs = [
        EvaluationPair(measuredValue: 102.0, referenceValue: 100.0, category: MeasurementCategory.ruralOpen, mode: MeasurementMode.offline),
        EvaluationPair(measuredValue: 104.0, referenceValue: 100.0, category: MeasurementCategory.ruralOpen, mode: MeasurementMode.offline),
        EvaluationPair(measuredValue: 106.0, referenceValue: 100.0, category: MeasurementCategory.ruralOpen, mode: MeasurementMode.offline),
      ];

      final report = analyzer.analyze(pairs);
      final expected = math.sqrt(56.0 / 3.0);

      expect(report.overallRMSE, closeTo(expected, 0.01));
      expect(report.overallRMSE, closeTo(4.32, 0.01));
    });

    test('reporte con lista vacía → estadísticas vacías', () {
      final report = analyzer.analyze([]);

      expect(report.pairs, isEmpty);
      expect(report.byCategory, isEmpty);
      expect(report.byMode, isEmpty);
      expect(report.overallRMSE, equals(0.0));
      expect(report.overallMeanError, equals(0.0));
      expect(report.onlineVsOffline, isNull);
    });

    test('reporte con un solo par → n=1, stdDev=0', () {
      final pairs = [
        EvaluationPair(measuredValue: 105.0, referenceValue: 100.0, category: MeasurementCategory.ruralOpen, mode: MeasurementMode.offline),
      ];

      final report = analyzer.analyze(pairs);
      final stats = report.byCategory[MeasurementCategory.ruralOpen.value]!;

      expect(stats.n, equals(1));
      expect(stats.mean, equals(5.0));
      expect(stats.stdDev, equals(0.0));
      expect(stats.rmse, equals(5.0));
      expect(stats.maxError, equals(5.0));
    });

    test('reporte con múltiples pares de diferentes categorías', () {
      final pairs = [
        EvaluationPair(measuredValue: 102.0, referenceValue: 100.0, category: MeasurementCategory.ruralOpen, mode: MeasurementMode.offline),
        EvaluationPair(measuredValue: 108.0, referenceValue: 100.0, category: MeasurementCategory.urban, mode: MeasurementMode.online),
        EvaluationPair(measuredValue: 104.0, referenceValue: 100.0, category: MeasurementCategory.ruralVegetation, mode: MeasurementMode.offline),
      ];

      final report = analyzer.analyze(pairs);

      expect(report.pairs.length, equals(3));
      expect(report.byCategory.length, equals(3));
      expect(report.byMode.length, equals(2));
      expect(report.overallMeanError, closeTo(4.67, 0.01));
      expect(report.overallRMSE, greaterThan(0));
    });
  });

  group('PrecisionAnalyzer - T-Test', () {
    late PrecisionAnalyzer analyzer;

    setUp(() {
      analyzer = const PrecisionAnalyzer();
    });

    test('t-test pareado: sample1=[1,2,3,4,5], sample2=[2,3,4,5,6] → df=4', () {
      final result = analyzer.calculateTTest([1.0, 2.0, 3.0, 4.0, 5.0], [2.0, 3.0, 4.0, 5.0, 6.0]);

      expect(result.degreesOfFreedom, equals(4.0));
    });

    test('t-test con muestras idénticas → t=0', () {
      final result = analyzer.calculateTTest([1.0, 2.0, 3.0, 4.0, 5.0], [1.0, 2.0, 3.0, 4.0, 5.0]);

      expect(result.tStatistic, equals(0.0));
    });

    test('t-test con muestras de diferente tamaño (Welch)', () {
      final result = analyzer.calculateTTest([1.0, 2.0, 3.0], [4.0, 5.0, 6.0, 7.0, 8.0]);

      expect(result.degreesOfFreedom, greaterThan(0));
    });

    test('t-test con muestras insuficientes → p=1', () {
      final result = analyzer.calculateTTest([1.0], [2.0]);

      expect(result.pValue, equals(1.0));
    });
  });
}
