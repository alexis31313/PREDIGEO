// Calculadora de distancias geodésicas de PrediGeo.
// Opera 100 % local, sin dependencias de red: Haversine para el uso diario
// y Vincenty (WGS84) como referencia de mayor exactitud sobre el elipsoide.
// Datum de referencia: MAGNA-SIRGAS (compatible WGS84 a esta escala).
//
// - [haversine]: distancia entre dos puntos (lat/lon en grados) en metros.
// - [vincenty]: distancia elipsoidal WGS84; si no converge, usa Haversine.
// - [pathLength]: suma de tramos consecutivos de un trayecto.
// - [perimeter]: como [pathLength] pero cerrando el polígono (último-primero).

import 'dart:math' as math;

import '../../entities/geo_point.dart';

class DistanceCalculator {
  DistanceCalculator._();

  /// Radio esférico medio usado por Haversine (mismo que AppConstants).
  static const double earthRadius = 6371000.0;

  // Parámetros del elipsoide WGS84 para Vincenty.
  static const double _wgs84A = 6378137.0;
  static const double _wgs84F = 1 / 298.257223563;
  static const double _wgs84B = _wgs84A * (1 - _wgs84F);

  static double _toRadians(double degrees) => degrees * math.pi / 180.0;

  /// Distancia Haversine entre dos puntos en metros.
  static double haversine(
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
    return earthRadius * c;
  }

  /// Distancia elipsoidal de Vincenty (fórmula inversa, WGS84) en metros.
  ///
  /// Itera hasta converger (tolerancia 1e-12, máximo 100 iteraciones).
  /// Si los puntos son coincidentes retorna 0; si no converge (antipodales),
  /// retorna el valor de [haversine] como respaldo.
  static double vincenty(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double tolerance = 1e-12;
    const int maxIterations = 100;

    final u1 = math.atan((1 - _wgs84F) * math.tan(_toRadians(lat1)));
    final u2 = math.atan((1 - _wgs84F) * math.tan(_toRadians(lat2)));
    final sinU1 = math.sin(u1);
    final cosU1 = math.cos(u1);
    final sinU2 = math.sin(u2);
    final cosU2 = math.cos(u2);

    final bigL = _toRadians(lon2 - lon1);
    var lambda = bigL;
    double sinSigma = 0;
    double cosSigma = 0;
    double sigma = 0;
    double sinAlpha = 0;
    double cosSqAlpha = 0;
    double cos2SigmaM = 0;

    for (var i = 0; i < maxIterations; i++) {
      final sinLambda = math.sin(lambda);
      final cosLambda = math.cos(lambda);
      sinSigma = math.sqrt(
        (cosU2 * sinLambda) * (cosU2 * sinLambda) +
            (cosU1 * sinU2 - sinU1 * cosU2 * cosLambda) *
                (cosU1 * sinU2 - sinU1 * cosU2 * cosLambda),
      );
      if (sinSigma == 0) return 0; // Puntos coincidentes.
      cosSigma = sinU1 * sinU2 + cosU1 * cosU2 * cosLambda;
      sigma = math.atan2(sinSigma, cosSigma);
      sinAlpha = cosU1 * cosU2 * sinLambda / sinSigma;
      cosSqAlpha = 1 - sinAlpha * sinAlpha;
      cos2SigmaM = cosSigma - 2 * sinU1 * sinU2 / cosSqAlpha;
      // Línea ecuatorial: cosSqAlpha puede ser 0.
      if (cos2SigmaM.isNaN) cos2SigmaM = 0;
      final bigC = _wgs84F / 16 * cosSqAlpha * (4 + _wgs84F * (4 - 3 * cosSqAlpha));
      final previousLambda = lambda;
      lambda = bigL +
          (1 - bigC) *
              _wgs84F *
              sinAlpha *
              (sigma +
                  bigC *
                      sinSigma *
                      (cos2SigmaM +
                          bigC * cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM)));
      if ((lambda - previousLambda).abs() < tolerance) {
        break;
      }
      if (i == maxIterations - 1) {
        return haversine(lat1, lon1, lat2, lon2);
      }
    }

    final uSq = cosSqAlpha * (_wgs84A * _wgs84A - _wgs84B * _wgs84B) /
        (_wgs84B * _wgs84B);
    final bigA = 1 +
        uSq / 16384 * (4096 + uSq * (-768 + uSq * (320 - 175 * uSq)));
    final bigB =
        uSq / 1024 * (256 + uSq * (-128 + uSq * (74 - 47 * uSq)));
    final deltaSigma = bigB *
        sinSigma *
        (cos2SigmaM +
            bigB /
                4 *
                (cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM) -
                    bigB /
                        6 *
                        cos2SigmaM *
                        (-3 + 4 * sinSigma * sinSigma) *
                        (-3 + 4 * cos2SigmaM * cos2SigmaM)));
    return _wgs84B * bigA * (sigma - deltaSigma);
  }

  /// Longitud total de un trayecto sumando tramos Haversine consecutivos.
  /// Con menos de 2 puntos retorna 0.
  static double pathLength(List<GeoPoint> points) {
    if (points.length < 2) return 0;
    var total = 0.0;
    for (var i = 0; i < points.length - 1; i++) {
      total += haversine(
        points[i].latitude,
        points[i].longitude,
        points[i + 1].latitude,
        points[i + 1].longitude,
      );
    }
    return total;
  }

  /// Perímetro de un polígono: como [pathLength] más el tramo de cierre
  /// (último punto al primero). Con menos de 2 puntos retorna 0.
  static double perimeter(List<GeoPoint> points) {
    if (points.length < 2) return 0;
    return pathLength(points) +
        haversine(
          points.last.latitude,
          points.last.longitude,
          points.first.latitude,
          points.first.longitude,
        );
  }

  /// Longitud de un tramo inclinado: √(d_horizontal² + Δh²).
  static double segmentSlopeLength(
    double horizontalMeters,
    double alt1,
    double alt2,
  ) {
    final deltaH = alt2 - alt1;
    return math.sqrt(
      horizontalMeters * horizontalMeters + deltaH * deltaH,
    );
  }

  /// Longitud de un trayecto sobre el terreno (3D), sumando cada tramo
  /// inclinado consecutivo. Con menos de 2 puntos retorna 0.
  static double pathLength3D(List<GeoPoint> points) {
    if (points.length < 2) return 0;
    var total = 0.0;
    for (var i = 0; i < points.length - 1; i++) {
      total += segmentSlopeLength(
        haversine(
          points[i].latitude,
          points[i].longitude,
          points[i + 1].latitude,
          points[i + 1].longitude,
        ),
        points[i].altitude,
        points[i + 1].altitude,
      );
    }
    return total;
  }

  /// Perímetro sobre el terreno (3D): como [pathLength3D] más el tramo de
  /// cierre inclinado. Con menos de 2 puntos retorna 0.
  static double perimeter3D(List<GeoPoint> points) {
    if (points.length < 2) return 0;
    return pathLength3D(points) +
        segmentSlopeLength(
          haversine(
            points.last.latitude,
            points.last.longitude,
            points.first.latitude,
            points.first.longitude,
          ),
          points.last.altitude,
          points.first.altitude,
        );
  }
}
