import 'dart:math' as math;

import '../../entities/geo_point.dart';

/// Calculadora de distancias geodésicas sobre el elipsoide de referencia.
///
/// PrediGeo trabaja con puntos GNSS en el datum MAGNA-SIRGAS, cuyo elipsoide
/// asociado es el GRS80 (prácticamente idéntico al WGS84). Esta clase ofrece:
///
/// - [haversine]: aproximación esférica rápida, usando un radio medio terrestre.
///   Es la opción por defecto para distancias cortas y trayectos, donde el
///   error frente a la solución elipsoidal es despreciable.
/// - [vincenty]: solución elipsoidal directa/inversa de alta precisión, con
///   respaldo automático a [haversine] si el algoritmo no converge (por ejemplo,
///   con puntos casi antipodales).
///
/// La clase es stateless: todos los métodos son estáticos.
class DistanceCalculator {
  DistanceCalculator._();

  /// Semieje mayor del elipsoide GRS80/WGS84, en metros.
  static const double semiMajorAxis = 6378137.0;

  /// Aplanamiento del elipsoide GRS80.
  static const double flattening = 1.0 / 298.257222101;

  /// Radio medio terrestre, en metros. Se usa en la aproximación de Haversine
  /// y como valor de respaldo cuando Vincenty no converge.
  static const double meanEarthRadius = 6371008.8;

  static const double _degreesToRadians = math.pi / 180.0;

  /// Distancia entre [a] y [b] mediante la fórmula de Haversine, en metros.
  ///
  /// [radius] permite ajustar el radio esférico; por defecto se usa el radio
  /// medio terrestre [meanEarthRadius].
  static double haversine(
    GeoPoint a,
    GeoPoint b, {
    double radius = meanEarthRadius,
  }) {
    final lat1 = a.latitude * _degreesToRadians;
    final lat2 = b.latitude * _degreesToRadians;
    final deltaLat = (b.latitude - a.latitude) * _degreesToRadians;
    final deltaLon = (b.longitude - a.longitude) * _degreesToRadians;

    final sinHalfLat = math.sin(deltaLat / 2);
    final sinHalfLon = math.sin(deltaLon / 2);

    final h = sinHalfLat * sinHalfLat +
        math.cos(lat1) * math.cos(lat2) * sinHalfLon * sinHalfLon;

    return 2 * radius * math.asin(math.min(1.0, math.sqrt(h)));
  }

  /// Distancia elipsoidal entre [a] y [b] mediante la fórmula inversa de
  /// Vincenty, en metros.
  ///
  /// Si el método iterativo no converge dentro de [maxIterations] o el error
  /// entre iteraciones cae por debajo de [tolerance], se devuelve el resultado
  /// de [haversine] como respaldo seguro.
  static double vincenty(
    GeoPoint a,
    GeoPoint b, {
    int maxIterations = 200,
    double tolerance = 1e-12,
  }) {
    if (a.latitude == b.latitude && a.longitude == b.longitude) {
      return 0.0;
    }

    const f = flattening;
    const semiMinorAxis = semiMajorAxis * (1 - f);
    final longitudeDifference = (b.longitude - a.longitude) * _degreesToRadians;

    final u1 = math.atan((1 - f) * math.tan(a.latitude * _degreesToRadians));
    final u2 = math.atan((1 - f) * math.tan(b.latitude * _degreesToRadians));

    final sinU1 = math.sin(u1);
    final cosU1 = math.cos(u1);
    final sinU2 = math.sin(u2);
    final cosU2 = math.cos(u2);

    var lambda = longitudeDifference;
    double? sinSigma;
    double? cosSigma;
    double? sigma;
    double? cosSquaredAlpha;
    double? cos2SigmaM;
    var converged = false;

    for (var iteration = 0; iteration < maxIterations; iteration++) {
      final sinLambda = math.sin(lambda);
      final cosLambda = math.cos(lambda);

      final sinSigmaValue = math.sqrt(
        math.pow(cosU2 * sinLambda, 2) +
            math.pow(cosU1 * sinU2 - sinU1 * cosU2 * cosLambda, 2),
      );

      if (sinSigmaValue == 0) {
        // Puntos coincidentes.
        return 0.0;
      }

      final cosSigmaValue = sinU1 * sinU2 + cosU1 * cosU2 * cosLambda;
      final sigmaValue = math.atan2(sinSigmaValue, cosSigmaValue);
      final sinAlpha = cosU1 * cosU2 * sinLambda / sinSigmaValue;
      final cosSquaredAlphaValue = 1 - sinAlpha * sinAlpha;

      final cos2SigmaMValue = cosSquaredAlphaValue != 0
          ? cosSigmaValue - 2 * sinU1 * sinU2 / cosSquaredAlphaValue
          : 0.0; // Línea ecuatorial.

      final c = f /
          16 *
          cosSquaredAlphaValue *
          (4 + f * (4 - 3 * cosSquaredAlphaValue));

      final previousLambda = lambda;
      lambda = longitudeDifference +
          (1 - c) *
              f *
              sinAlpha *
              (sigmaValue +
                  c *
                      sinSigmaValue *
                      (cos2SigmaMValue +
                          c *
                              cosSigmaValue *
                              (-1 + 2 * cos2SigmaMValue * cos2SigmaMValue)));

      sinSigma = sinSigmaValue;
      cosSigma = cosSigmaValue;
      sigma = sigmaValue;
      cosSquaredAlpha = cosSquaredAlphaValue;
      cos2SigmaM = cos2SigmaMValue;

      if ((lambda - previousLambda).abs() < tolerance) {
        converged = true;
        break;
      }
    }

    if (!converged ||
        sinSigma == null ||
        cosSigma == null ||
        sigma == null ||
        cosSquaredAlpha == null ||
        cos2SigmaM == null) {
      return haversine(a, b);
    }

    final uSquared = cosSquaredAlpha *
        (semiMajorAxis * semiMajorAxis - semiMinorAxis * semiMinorAxis) /
        (semiMinorAxis * semiMinorAxis);

    final coefficientA = 1 +
        uSquared /
            16384 *
            (4096 + uSquared * (-768 + uSquared * (320 - 175 * uSquared)));

    final coefficientB = uSquared /
        1024 *
        (256 + uSquared * (-128 + uSquared * (74 - 47 * uSquared)));

    final deltaSigma = coefficientB *
        sinSigma *
        (cos2SigmaM +
            coefficientB /
                4 *
                (cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM) -
                    coefficientB /
                        6 *
                        cos2SigmaM *
                        (-3 + 4 * sinSigma * sinSigma) *
                        (-3 + 4 * cos2SigmaM * cos2SigmaM)));

    return semiMinorAxis * coefficientA * (sigma - deltaSigma);
  }

  /// Longitud de un trayecto abierto: suma de las distancias entre puntos
  /// consecutivos. Devuelve `0` si hay menos de dos puntos.
  static double pathLength(
    List<GeoPoint> points, {
    bool useVincenty = false,
  }) {
    if (points.length < 2) return 0.0;

    var total = 0.0;
    for (var i = 0; i < points.length - 1; i++) {
      total += useVincenty
          ? vincenty(points[i], points[i + 1])
          : haversine(points[i], points[i + 1]);
    }
    return total;
  }

  /// Perímetro de un polígono cerrado: recorre los puntos y añade el segmento
  /// que une el último con el primero. Devuelve `0` si hay menos de dos puntos.
  static double perimeter(
    List<GeoPoint> points, {
    bool useVincenty = false,
  }) {
    if (points.length < 2) return 0.0;

    var total = pathLength(points, useVincenty: useVincenty);
    total += useVincenty
        ? vincenty(points.last, points.first)
        : haversine(points.last, points.first);
    return total;
  }
}
