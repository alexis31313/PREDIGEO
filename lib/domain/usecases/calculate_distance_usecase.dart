import 'dart:math' as math;

import '../entities/geo_point.dart';

/// Caso de uso que calcula la distancia total recorrida entre puntos GNSS.
///
/// Suma las distancias Haversine entre cada par de puntos consecutivos, lo que
/// evita el error de las proyecciones planas en trayectos largos.
class CalculateDistanceUsecase {
  static const double _earthRadius = 6371000.0;

  /// Calcula la distancia total en metros. Devuelve 0.0 si hay menos de dos
  /// puntos o si todos los puntos coinciden.
  Future<double> call(List<GeoPoint> points) async {
    if (points.length < 2) return 0.0;

    var totalDistance = 0.0;
    for (var i = 0; i < points.length - 1; i++) {
      totalDistance += _haversineDistance(
        points[i].latitude,
        points[i].longitude,
        points[i + 1].latitude,
        points[i + 1].longitude,
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
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return _earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * math.pi / 180.0;
}
