import 'dart:math' as math;
import '../entities/coordinate.dart';

/// Caso de uso que calcula la distancia total recorrida entre una serie de coordenadas GPS.
class CalculateDistanceUsecase {
  /// Calcula la distancia total en metros sumando las distancias haversine
  /// entre cada par de coordenadas consecutivas.
  Future<double> call(List<Coordinate> coordinates) async {
    if (coordinates.length < 2) {
      return 0.0;
    }

    double totalDistance = 0.0;

    for (int i = 0; i < coordinates.length - 1; i++) {
      totalDistance += _haversineDistance(
        coordinates[i].latitude,
        coordinates[i].longitude,
        coordinates[i + 1].latitude,
        coordinates[i + 1].longitude,
      );
    }

    return totalDistance;
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
