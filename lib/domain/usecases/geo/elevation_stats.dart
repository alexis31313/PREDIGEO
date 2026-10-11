import 'dart:math' as math;

import '../../entities/geo_point.dart';
import './distance_calculator.dart';

/// Estadísticas de altitud y relieve calculadas a partir de una secuencia de
/// puntos GNSS.
///
/// El relieve solo es fiable cuando la componente vertical del receptor es
/// aceptable: la altitud GNSS suele ser bastante menos precisa que la posición
/// horizontal. Por eso [ElevationStats.fromPoints] descarta los puntos cuya
/// precisión horizontal supera [maxAccuracy] antes de calcular nada.
///
/// La entidad tolera entradas degeneradas: listas vacías, un único punto o
/// puntos con el mismo emplazamiento (distancia horizontal nula) no provocan
/// errores; en esos casos los campos que no pueden calcularse quedan en `null`
/// o en `0`.
class ElevationStats {
  /// Número de puntos considerados en el cálculo (no descartados).
  final int sampleCount;

  /// Número de puntos descartados por baja precisión.
  final int ignoredCount;

  /// Altitud mínima del recorrido, en metros. `null` si no hay datos.
  final double? minAltitude;

  /// Altitud máxima del recorrido, en metros. `null` si no hay datos.
  final double? maxAltitude;

  /// Altitud media del recorrido, en metros. `null` si no hay datos.
  final double? averageAltitude;

  /// Desnivel positivo acumulado (suma de ascensos), en metros.
  final double positiveGain;

  /// Desnivel negativo acumulado (suma de descensos, valor absoluto), en metros.
  final double negativeGain;

  /// Pendiente media a lo largo del recorrido, en porcentaje.
  ///
  /// Se calcula como el desnivel total recorrido (ascensos + descensos, en
  /// valor absoluto) dividido entre la distancia horizontal acumulada.
  /// `null` si no hay datos; `0` si la distancia horizontal es nula.
  final double? averageSlopePercent;

  const ElevationStats({
    required this.sampleCount,
    required this.ignoredCount,
    this.minAltitude,
    this.maxAltitude,
    this.averageAltitude,
    this.positiveGain = 0.0,
    this.negativeGain = 0.0,
    this.averageSlopePercent,
  });

  /// Resultado vacío, útil como valor inicial o de respaldo.
  static const ElevationStats empty = ElevationStats(
    sampleCount: 0,
    ignoredCount: 0,
    positiveGain: 0.0,
    negativeGain: 0.0,
  );

  /// `true` cuando hay al menos un punto válido con altitud.
  bool get hasData => sampleCount > 0 && averageAltitude != null;

  /// Rango de altitud (máxima - mínima), en metros. `null` si no hay datos.
  double? get altitudeRange {
    final min = minAltitude;
    final max = maxAltitude;
    if (min == null || max == null) return null;
    return max - min;
  }

  /// Calcula las estadísticas de relieve de [points].
  ///
  /// [maxAccuracy] es el umbral de precisión horizontal, en metros, por debajo
  /// del cual un punto se considera fiable para el cálculo vertical.
  factory ElevationStats.fromPoints(
    List<GeoPoint> points, {
    double maxAccuracy = 20.0,
  }) {
    if (points.isEmpty) return empty;

    final valid = <GeoPoint>[];
    for (final point in points) {
      if (point.accuracy <= maxAccuracy) valid.add(point);
    }

    final ignored = points.length - valid.length;
    if (valid.isEmpty) {
      return ElevationStats(
        sampleCount: 0,
        ignoredCount: ignored,
      );
    }

    var min = valid.first.altitude;
    var max = valid.first.altitude;
    var sum = 0.0;
    for (final point in valid) {
      min = math.min(min, point.altitude);
      max = math.max(max, point.altitude);
      sum += point.altitude;
    }

    var positive = 0.0;
    var negative = 0.0;
    var horizontalDistance = 0.0;
    var verticalTravel = 0.0;
    for (var i = 0; i < valid.length - 1; i++) {
      final delta = valid[i + 1].altitude - valid[i].altitude;
      if (delta > 0) {
        positive += delta;
      } else {
        negative += -delta;
      }

      final distance = DistanceCalculator.haversine(valid[i], valid[i + 1]);
      if (distance > 0) {
        horizontalDistance += distance;
        verticalTravel += delta.abs();
      }
    }

    final averageSlope = horizontalDistance > 0
        ? (verticalTravel / horizontalDistance) * 100.0
        : 0.0;

    return ElevationStats(
      sampleCount: valid.length,
      ignoredCount: ignored,
      minAltitude: min,
      maxAltitude: max,
      averageAltitude: sum / valid.length,
      positiveGain: positive,
      negativeGain: negative,
      averageSlopePercent: averageSlope,
    );
  }
}
