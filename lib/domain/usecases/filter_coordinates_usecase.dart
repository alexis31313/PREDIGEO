import '../entities/coordinate.dart';

/// Caso de uso que filtra y limpia coordenadas GPS aplicando un filtro de Kalman
/// y eliminación de valores atípicos.
class FilterCoordinatesUsecase {
  /// Filtra una lista de coordenadas aplicando un filtro de Kalman simple
  /// y/o eliminación de valores atípicos según los parámetros especificados.
  List<Coordinate> call(
    List<Coordinate> coordinates, {
    bool kalman = true,
    bool removeOutliers = true,
    double accuracyThreshold = 10.0,
  }) {
    if (coordinates.isEmpty) return [];

    List<Coordinate> filtered = List.from(coordinates);

    if (removeOutliers) {
      filtered = _removeOutliers(filtered, accuracyThreshold);
    }

    if (kalman) {
      filtered = _applyKalmanFilter(filtered);
    }

    return filtered;
  }

  List<Coordinate> _removeOutliers(List<Coordinate> coordinates, double threshold) {
    if (coordinates.length < 3) return coordinates;

    final List<double> accuracies = coordinates.map((c) => c.accuracy).toList();
    final double meanAccuracy = accuracies.reduce((a, b) => a + b) / accuracies.length;
    final double variance = accuracies
            .map((a) => (a - meanAccuracy) * (a - meanAccuracy))
            .reduce((a, b) => a + b) /
        accuracies.length;
    final double stdDev = variance > 0 ? variance : 1.0;

    return coordinates.where((c) {
      final double zScore = (c.accuracy - meanAccuracy) / stdDev;
      return zScore.abs() <= 2.0 && c.accuracy <= threshold;
    }).toList();
  }

  List<Coordinate> _applyKalmanFilter(List<Coordinate> coordinates) {
    if (coordinates.isEmpty) return coordinates;

    final List<Coordinate> result = [];
    double latEstimate = coordinates[0].latitude;
    double lngEstimate = coordinates[0].longitude;
    double estimateError = 1.0;
    const double processNoise = 0.01;

    for (final coord in coordinates) {
      estimateError += processNoise;

      final double kalmanGain = estimateError / (estimateError + coord.accuracy);
      latEstimate += kalmanGain * (coord.latitude - latEstimate);
      lngEstimate += kalmanGain * (coord.longitude - lngEstimate);
      estimateError *= (1 - kalmanGain);

      result.add(coord.copyWith(
        latitude: latEstimate,
        longitude: lngEstimate,
      ));
    }

    return result;
  }
}
