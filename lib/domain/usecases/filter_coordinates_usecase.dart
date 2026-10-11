import 'dart:math' as math;

import '../entities/geo_point.dart';

/// Caso de uso que filtra y limpia puntos GNSS para reducir el error de la
/// señal GPS antes de calcular áreas y distancias.
///
/// Combina dos técnicas:
/// 1. Eliminación de valores atípicos por puntaje z de la precisión reportada.
/// 2. Filtro de Kalman 1D que suaviza latitud y longitud.
///
/// Los puntos descartados no se pierden: se conservan los valores originales en
/// `accuracy` para poder auditar el filtrado en la evaluación de precisión.
class FilterCoordinatesUsecase {
  /// Filtra una lista de puntos.
  ///
  /// - [removeOutliers]: descarta puntos cuya precisión sea peor que
  ///   [accuracyThreshold] o cuya desviación sea superior a 2 desviaciones
  ///   estándar.
  /// - [kalman]: aplica el suavizado de Kalman sobre los puntos válidos.
  Future<List<GeoPoint>> call(
    List<GeoPoint> points, {
    bool kalman = true,
    bool removeOutliers = true,
    double accuracyThreshold = 10.0,
  }) async {
    if (points.isEmpty) return <GeoPoint>[];

    var filtered = List<GeoPoint>.from(points);

    if (removeOutliers) {
      filtered = _removeOutliers(filtered, accuracyThreshold);
    }

    if (kalman) {
      filtered = _applyKalmanFilter(filtered);
    }

    return filtered;
  }

  /// Elimina puntos atípicos usando la precisión horizontal reportada.
  List<GeoPoint> _removeOutliers(
    List<GeoPoint> points,
    double threshold,
  ) {
    if (points.length < 3) return points;

    final accuracies = points.map((point) => point.accuracy);
    final meanAccuracy = accuracies.reduce((a, b) => a + b) / points.length;
    final variance = points.fold<double>(
          0.0,
          (sum, point) =>
              sum + math.pow(point.accuracy - meanAccuracy, 2).toDouble(),
        ) /
        points.length;
    final stdDev = variance > 0 ? math.sqrt(variance) : 1.0;

    return points.where((point) {
      final zScore = (point.accuracy - meanAccuracy) / stdDev;
      return zScore.abs() <= 2.0 && point.accuracy <= threshold;
    }).toList();
  }

  /// Suaviza latitud y longitud con un filtro de Kalman 1D.
  List<GeoPoint> _applyKalmanFilter(List<GeoPoint> points) {
    if (points.isEmpty) return points;

    final result = <GeoPoint>[];
    var latEstimate = points.first.latitude;
    var lngEstimate = points.first.longitude;
    var estimateError = 1.0;
    const processNoise = 0.01;

    for (final point in points) {
      estimateError += processNoise;

      final kalmanGain = estimateError / (estimateError + point.accuracy);
      latEstimate += kalmanGain * (point.latitude - latEstimate);
      lngEstimate += kalmanGain * (point.longitude - lngEstimate);
      estimateError *= (1 - kalmanGain);

      result.add(point.copyWith(latitude: latEstimate, longitude: lngEstimate));
    }

    return result;
  }
}
