import 'dart:math' as math;
import '../entities/coordinate.dart';

/// Caso de uso que evalúa la precisión de coordenadas medidas contra coordenadas de referencia.
class EvaluateAccuracyUsecase {
  /// Compara coordenadas medidas con coordenadas de referencia y calcula
  /// métricas de error: RMSE, error absoluto y error porcentual.
  Map<String, double> call(
    List<Coordinate> measured,
    List<Coordinate> reference,
  ) {
    if (measured.isEmpty || reference.isEmpty) {
      return {
        'rmse': 0.0,
        'absoluteError': 0.0,
        'percentError': 0.0,
      };
    }

    final int count = math.min(measured.length, reference.length);
    double sumSquaredError = 0.0;
    double sumAbsoluteError = 0.0;
    double sumReferenceDistance = 0.0;

    for (int i = 0; i < count; i++) {
      final double error = _haversineDistance(
        measured[i].latitude,
        measured[i].longitude,
        reference[i].latitude,
        reference[i].longitude,
      );

      sumSquaredError += error * error;
      sumAbsoluteError += error;
      sumReferenceDistance += _haversineDistance(
        0.0,
        0.0,
        reference[i].latitude,
        reference[i].longitude,
      );
    }

    final double rmse = math.sqrt(sumSquaredError / count);
    final double absoluteError = sumAbsoluteError / count;
    final double percentError = sumReferenceDistance > 0
        ? (absoluteError / (sumReferenceDistance / count)) * 100.0
        : 0.0;

    return {
      'rmse': rmse,
      'absoluteError': absoluteError,
      'percentError': percentError,
    };
  }

  double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000.0;

    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }
}
