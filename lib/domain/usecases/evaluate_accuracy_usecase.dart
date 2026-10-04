import 'dart:math' as math;

import '../entities/geo_point.dart';

/// Caso de uso que evalúa la precisión de los puntos medidos comparándolos con
/// puntos de referencia conocidos del terreno.
///
/// Calcula las tres métricas usadas en la evaluación de PrediGeo:
/// - RMSE (error cuadrático medio de las distancias de error);
/// - error absoluto medio (en metros);
/// - error porcentual medio, relativo a la distancia de la referencia al ecuador.
class EvaluateAccuracyUsecase {
  static const double _earthRadius = 6371000.0;

  /// Compara las listas de puntos medidos y de referencia.
  ///
  /// Devuelve un mapa con las claves `rmse`, `absoluteError` y `percentError`.
  /// Si alguna de las listas está vacía devuelve todas las métricas en cero.
  Map<String, double> call(
    List<GeoPoint> measured,
    List<GeoPoint> reference,
  ) {
    if (measured.isEmpty || reference.isEmpty) {
      return {
        'rmse': 0.0,
        'absoluteError': 0.0,
        'percentError': 0.0,
      };
    }

    final count = math.min(measured.length, reference.length);
    var sumSquaredError = 0.0;
    var sumAbsoluteError = 0.0;
    var sumReferenceDistance = 0.0;

    for (var i = 0; i < count; i++) {
      final error = _haversineDistance(
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

    final rmse = math.sqrt(sumSquaredError / count);
    final absoluteError = sumAbsoluteError / count;
    final percentError = sumReferenceDistance > 0
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