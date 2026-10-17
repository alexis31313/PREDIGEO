// Analizador de precisión de las mediciones de campo.
//
// Calcula, para cada par (valor medido, valor de referencia), el error
// absoluto y el error porcentual, y agrega los resultados por categoría de
// terreno y por modalidad de captura. Incluye una prueba t para comparar la
// precisión entre las capturas en línea y sin conexión.

import 'dart:math' as math;

import '../../entities/measurement_enums.dart';

/// Par de comparación entre el valor calculado por PrediGeo y el valor de
/// referencia del terreno.
class EvaluationPair {
  /// Valor calculado por PrediGeo (área en m² o distancia en m).
  final double measuredValue;

  /// Valor de referencia del terreno (área en m² o distancia en m).
  final double referenceValue;

  /// Categoría del terreno donde se realizó la medición.
  final MeasurementCategory category;

  /// Modalidad de captura: en línea o sin conexión.
  final MeasurementMode mode;

  const EvaluationPair({
    required this.measuredValue,
    required this.referenceValue,
    required this.category,
    required this.mode,
  });

  /// Diferencia absoluta entre el valor medido y el de referencia.
  double get absoluteError => (measuredValue - referenceValue).abs();

  /// Error porcentual respecto al valor de referencia.
  /// Devuelve 0 cuando la referencia es cero para evitar divisiones por cero.
  double get percentError {
    if (referenceValue == 0) return 0;
    return absoluteError / referenceValue.abs() * 100;
  }

  @override
  String toString() => 'EvaluationPair(measured: $measuredValue, '
      'reference: $referenceValue, category: ${category.value}, '
      'mode: ${mode.value})';
}

/// Estadísticas de error absoluto agregadas por categoría de terreno o por
/// modalidad de captura.
class CategoryStats {
  /// Cantidad de pares evaluados en el grupo.
  final int n;

  /// Error absoluto medio.
  final double mean;

  /// Desviación estándar muestral del error absoluto.
  final double stdDev;

  /// Raíz del error cuadrático medio del error absoluto.
  final double rmse;

  /// Mayor error absoluto observado en el grupo.
  final double maxError;

  const CategoryStats({
    required this.n,
    required this.mean,
    required this.stdDev,
    required this.rmse,
    required this.maxError,
  });

  @override
  String toString() => 'CategoryStats(n: $n, mean: $mean, stdDev: $stdDev, '
      'rmse: $rmse, maxError: $maxError)';
}

/// Estadísticas de error absoluto agregadas por modalidad de captura.
/// Misma semántica que [CategoryStats].
class ModeStats {
  /// Cantidad de pares evaluados en el grupo.
  final int n;

  /// Error absoluto medio.
  final double mean;

  /// Desviación estándar muestral del error absoluto.
  final double stdDev;

  /// Raíz del error cuadrático medio del error absoluto.
  final double rmse;

  /// Mayor error absoluto observado en el grupo.
  final double maxError;

  const ModeStats({
    required this.n,
    required this.mean,
    required this.stdDev,
    required this.rmse,
    required this.maxError,
  });

  @override
  String toString() => 'ModeStats(n: $n, mean: $mean, stdDev: $stdDev, '
      'rmse: $rmse, maxError: $maxError)';
}

/// Resultado de una prueba t sobre muestras relacionadas o independientes.
class TTestResult {
  /// Estadístico t calculado.
  final double tStatistic;

  /// Grados de libertad de la prueba.
  final double degreesOfFreedom;

  /// Valor p aproximado de dos colas.
  final double pValue;

  const TTestResult({
    required this.tStatistic,
    required this.degreesOfFreedom,
    required this.pValue,
  });

  /// `true` cuando el valor p es menor que 0.05.
  bool get isSignificant => pValue < 0.05;

  @override
  String toString() => 'TTestResult(t: $tStatistic, df: $degreesOfFreedom, '
      'p: $pValue, significant: $isSignificant)';
}

/// Informe completo de la evaluación de precisión de campo.
class EvaluationReport {
  /// Pares evaluados, en el mismo orden en que se analizaron.
  final List<EvaluationPair> pairs;

  /// Estadísticas agregadas por categoría de terreno.
  /// Clave: [MeasurementCategory.value].
  final Map<String, CategoryStats> byCategory;

  /// Estadísticas agregadas por modalidad de captura.
  /// Clave: [MeasurementMode.value].
  final Map<String, ModeStats> byMode;

  /// RMSE global del error absoluto, considerando todos los pares.
  final double overallRMSE;

  /// Error absoluto medio global, considerando todos los pares.
  final double overallMeanError;

  /// Prueba t entre los errores de las capturas en línea y sin conexión.
  /// `null` cuando no hay suficientes datos en ambos grupos (mínimo 2 por
  /// grupo).
  final TTestResult? onlineVsOffline;

  const EvaluationReport({
    required this.pairs,
    required this.byCategory,
    required this.byMode,
    required this.overallRMSE,
    required this.overallMeanError,
    this.onlineVsOffline,
  });

  @override
  String toString() => 'EvaluationReport(pairs: ${pairs.length}, '
      'overallRMSE: $overallRMSE, overallMeanError: $overallMeanError, '
      'onlineVsOffline: $onlineVsOffline)';
}

/// Calcula las métricas de precisión de las mediciones frente a los valores
/// de referencia registrados en campo.
class PrecisionAnalyzer {
  const PrecisionAnalyzer();

  /// Evalúa una lista de pares y devuelve el informe con las métricas
  /// globales, por categoría y por modalidad.
  ///
  /// Los grupos sin pares se omiten de [EvaluationReport.byCategory] y
  /// [EvaluationReport.byMode]. La prueba [EvaluationReport.onlineVsOffline]
  /// solo se calcula cuando hay al menos 2 pares en cada modalidad.
  EvaluationReport analyze(List<EvaluationPair> pairs) {
    final errors =
        pairs.map((pair) => pair.absoluteError).toList(growable: false);

    final byCategory = <String, CategoryStats>{};
    for (final category in MeasurementCategory.values) {
      final groupErrors = errorsOf(pairs, category: category);
      if (groupErrors.isEmpty) continue;
      byCategory[category.value] = _buildCategoryStats(groupErrors);
    }

    final byMode = <String, ModeStats>{};
    for (final mode in MeasurementMode.values) {
      final groupErrors = errorsOf(pairs, mode: mode);
      if (groupErrors.isEmpty) continue;
      byMode[mode.value] = _buildModeStats(groupErrors);
    }

    final overallRMSE = _rmse(errors);
    final overallMeanError =
        errors.isEmpty ? 0.0 : _mean(errors);

    final onlineErrors = errorsOf(pairs, mode: MeasurementMode.online);
    final offlineErrors = errorsOf(pairs, mode: MeasurementMode.offline);
    final TTestResult? onlineVsOffline;
    if (onlineErrors.length >= 2 && offlineErrors.length >= 2) {
      onlineVsOffline = calculateTTest(onlineErrors, offlineErrors);
    } else {
      onlineVsOffline = null;
    }

    return EvaluationReport(
      pairs: List<EvaluationPair>.unmodifiable(pairs),
      byCategory: Map<String, CategoryStats>.unmodifiable(byCategory),
      byMode: Map<String, ModeStats>.unmodifiable(byMode),
      overallRMSE: overallRMSE,
      overallMeanError: overallMeanError,
      onlineVsOffline: onlineVsOffline,
    );
  }

  /// Ejecuta una prueba t sobre dos muestras.
  ///
  /// Cuando ambas muestras tienen la misma longitud (mínimo 2), se aplica una
  /// prueba t pareada sobre las diferencias elemento a elemento. Si las
  /// longitudes difieren, se aplica la prueba t de Welch (muestras
  /// independientes con varianzas desiguales). En ambos casos el valor p es
  /// aproximado, de dos colas.
  TTestResult calculateTTest(List<double> sample1, List<double> sample2) {
    if (sample1.length == sample2.length && sample1.length >= 2) {
      return _pairedTTest(sample1, sample2);
    }
    if (sample1.length >= 2 && sample2.length >= 2) {
      return _welchTTest(sample1, sample2);
    }
    return const TTestResult(
      tStatistic: 0,
      degreesOfFreedom: 0,
      pValue: 1,
    );
  }

  /// Errores absolutos de los pares que pertenecen a la categoría indicada.
  List<double> errorsOf(
    List<EvaluationPair> pairs, {
    MeasurementCategory? category,
    MeasurementMode? mode,
  }) {
    final errors = <double>[];
    for (final pair in pairs) {
      if (category != null && pair.category != category) continue;
      if (mode != null && pair.mode != mode) continue;
      errors.add(pair.absoluteError);
    }
    return errors;
  }

  /// Construye las estadísticas de error absoluto para un grupo de errores.
  CategoryStats _buildCategoryStats(List<double> errors) {
    return CategoryStats(
      n: errors.length,
      mean: _mean(errors),
      stdDev: _stdDev(errors),
      rmse: _rmse(errors),
      maxError: errors.reduce((a, b) => a > b ? a : b),
    );
  }

  /// Construye las estadísticas de error absoluto para un grupo de errores.
  ModeStats _buildModeStats(List<double> errors) {
    return ModeStats(
      n: errors.length,
      mean: _mean(errors),
      stdDev: _stdDev(errors),
      rmse: _rmse(errors),
      maxError: errors.reduce((a, b) => a > b ? a : b),
    );
  }

  /// Media aritmética de una lista no vacía.
  double _mean(List<double> values) {
    var sum = 0.0;
    for (final value in values) {
      sum += value;
    }
    return sum / values.length;
  }

  /// Desviación estándar muestral (n - 1). Devuelve 0 para un solo valor.
  double _stdDev(List<double> values) {
    if (values.length < 2) return 0;
    final mean = _mean(values);
    var sumSquares = 0.0;
    for (final value in values) {
      final diff = value - mean;
      sumSquares += diff * diff;
    }
    return math.sqrt(sumSquares / (values.length - 1));
  }

  /// Raíz del error cuadrático medio.
  double _rmse(List<double> errors) {
    if (errors.isEmpty) return 0;
    var sumSquares = 0.0;
    for (final error in errors) {
      sumSquares += error * error;
    }
    return math.sqrt(sumSquares / errors.length);
  }

  /// Prueba t pareada: compara las diferencias de cada par de observaciones.
  TTestResult _pairedTTest(List<double> sample1, List<double> sample2) {
    final n = sample1.length;
    final differences = <double>[
      for (var i = 0; i < n; i++) sample1[i] - sample2[i],
    ];
    final mean = _mean(differences);
    final stdDev = _stdDev(differences);

    if (stdDev == 0) {
      final isNull = mean == 0;
      return TTestResult(
        tStatistic: isNull
            ? 0
            : (mean > 0 ? double.infinity : double.negativeInfinity),
        degreesOfFreedom: (n - 1).toDouble(),
        pValue: isNull ? 1.0 : 0.0,
      );
    }

    final t = mean / (stdDev / math.sqrt(n));
    return TTestResult(
      tStatistic: t,
      degreesOfFreedom: (n - 1).toDouble(),
      pValue: _pValueFromT(t.abs(), (n - 1).toDouble()),
    );
  }

  /// Prueba t de Welch: muestras independientes de distinto tamaño y varianza.
  TTestResult _welchTTest(List<double> sample1, List<double> sample2) {
    final n1 = sample1.length;
    final n2 = sample2.length;
    final mean1 = _mean(sample1);
    final mean2 = _mean(sample2);
    final variance1 = _stdDev(sample1) * _stdDev(sample1);
    final variance2 = _stdDev(sample2) * _stdDev(sample2);
    final se = variance1 / n1 + variance2 / n2;

    if (se == 0) {
      final isNull = mean1 == mean2;
      return TTestResult(
        tStatistic: isNull
            ? 0
            : (mean1 > mean2 ? double.infinity : double.negativeInfinity),
        degreesOfFreedom: (n1 + n2 - 2).toDouble(),
        pValue: isNull ? 1.0 : 0.0,
      );
    }

    final t = (mean1 - mean2) / math.sqrt(se);
    final df = se * se /
        ((variance1 / n1) * (variance1 / n1) / (n1 - 1) +
            (variance2 / n2) * (variance2 / n2) / (n2 - 1));
    return TTestResult(
      tStatistic: t,
      degreesOfFreedom: df,
      pValue: _pValueFromT(t.abs(), df),
    );
  }

  /// Valor p de dos colas de la distribución t con [df] grados de libertad.
  ///
  /// Usa la relación entre la distribución t y la función beta incompleta
  /// regularizada: p = I_x(df/2, 1/2) con x = df / (df + t²).
  double _pValueFromT(double tAbs, double df) {
    if (df <= 0) return 1.0;
    final x = df / (df + tAbs * tAbs);
    return _regularizedIncompleteBeta(df / 2, 0.5, x);
  }

  /// Función beta incompleta regularizada I_x(a, b) mediante fracción
  /// continua (algoritmo de Numerical Recipes).
  double _regularizedIncompleteBeta(double a, double b, double x) {
    if (x <= 0) return 0;
    if (x >= 1) return 1;
    final logBt = _logGamma(a + b) -
        _logGamma(a) -
        _logGamma(b) +
        a * math.log(x) +
        b * math.log(1 - x);
    final bt = math.exp(logBt);
    if (x < (a + 1) / (a + b + 2)) {
      return bt * _continuedFractionBeta(a, b, x) / a;
    }
    return 1 - bt * _continuedFractionBeta(b, a, 1 - x) / b;
  }

  /// Fracción continua para la función beta incompleta (betacf).
  double _continuedFractionBeta(double a, double b, double x) {
    const maxIterations = 200;
    const epsilon = 3e-12;
    const minFloat = 1e-300;

    final qab = a + b;
    final qap = a + 1;
    final qam = a - 1;
    var c = 1.0;
    var d = 1.0 - qab * x / qap;
    if (d.abs() < minFloat) d = minFloat;
    d = 1 / d;
    var h = d;

    for (var m = 1; m <= maxIterations; m++) {
      final m2 = 2 * m;
      var aa = m * (b - m) * x / ((qam + m2) * (a + m2));
      d = 1 + aa * d;
      if (d.abs() < minFloat) d = minFloat;
      c = 1 + aa / c;
      if (c.abs() < minFloat) c = minFloat;
      d = 1 / d;
      h *= d * c;

      aa = -(a + m) * (qab + m) * x / ((a + m2) * (qap + m2));
      d = 1 + aa * d;
      if (d.abs() < minFloat) d = minFloat;
      c = 1 + aa / c;
      if (c.abs() < minFloat) c = minFloat;
      d = 1 / d;
      final delta = d * c;
      h *= delta;
      if ((delta - 1).abs() < epsilon) break;
    }
    return h;
  }

  /// Logaritmo de la función gamma (aproximación de Lanczos).
  double _logGamma(double x) {
    const coefficients = <double>[
      0.99999999999980993,
      676.5203681218851,
      -1259.1392167224028,
      771.32342877765313,
      -176.61502916214059,
      12.507343278686905,
      -0.13857109526572012,
      9.9843695780195716e-6,
      1.5056327351493116e-7,
    ];

    if (x < 0.5) {
      return math.log(math.pi / math.sin(math.pi * x)) - _logGamma(1 - x);
    }

    final z = x - 1;
    var sum = coefficients[0];
    for (var i = 1; i < coefficients.length; i++) {
      sum += coefficients[i] / (z + i);
    }
    final t = z + 7.5;
    return 0.5 * math.log(2 * math.pi) +
        (z + 0.5) * math.log(t) -
        t +
        math.log(sum);
  }
}
