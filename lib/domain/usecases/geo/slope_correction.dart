// Corrección por relieve (pendiente) de PrediGeo.
// Opera 100 % local, sin dependencias de red.
//
// La distancia y el área "planimétricas" se miden sobre el plano horizontal
// y subestiman la realidad en terrenos con pendiente: caminar una ladera
// recorre más metros que su proyección en el mapa. Este módulo calcula la
// variante "sobre el terreno" a partir de la altitud de cada punto:
//
// - Distancia 3D por tramo: d = √(d_horizontal² + Δh²).
// - Área sobre el terreno ≈ área_planimétrica / cos(pendiente_media),
//   donde la pendiente media se pondera por la longitud de cada tramo.
//   Es una estimación documentada (supone inclinación media uniforme),
//   válida para predios con pendiente razonablemente homogénea.
//
// Convención de la app: se persiste el valor planimétrico (comparable con
// referencias IGAC/topográficas, que también son planimétricas) y se
// muestra el valor sobre el terreno como información complementaria.
// Los valores con relieve dependen de la precisión vertical del GPS del
// teléfono (±10-15 m típico), siempre peor que la horizontal.

import 'dart:math' as math;

import '../../entities/geo_point.dart';
import 'distance_calculator.dart';

class SlopeCorrection {
  SlopeCorrection._();

  /// Pendiente media en radianes, ponderada por la longitud de cada tramo.
  ///
  /// Si [closed] es `true` incluye el tramo de cierre (último-primero),
  /// adecuado para polígonos de área; en `false` sigue el camino recorrido,
  /// adecuado para trayectos. Con menos de 2 puntos retorna 0.
  static double meanSlopeRadians(
    List<GeoPoint> points, {
    bool closed = true,
  }) {
    if (points.length < 2) return 0;
    var weightedSum = 0.0;
    var totalLength = 0.0;

    void accumulate(GeoPoint a, GeoPoint b) {
      final horizontal = DistanceCalculator.haversine(
        a.latitude,
        a.longitude,
        b.latitude,
        b.longitude,
      );
      if (horizontal <= 0) return;
      final slope = math.atan(
        (b.altitude - a.altitude).abs() / horizontal,
      );
      weightedSum += slope * horizontal;
      totalLength += horizontal;
    }

    for (var i = 0; i < points.length - 1; i++) {
      accumulate(points[i], points[i + 1]);
    }
    if (closed && points.length >= 3) {
      accumulate(points.last, points.first);
    }
    if (totalLength <= 0) return 0;
    return weightedSum / totalLength;
  }

  /// Factor de corrección: por cuánto multiplicar el área planimétrica.
  /// En terreno plano retorna 1.
  static double slopeFactor(
    List<GeoPoint> points, {
    bool closed = true,
  }) {
    final cosSlope = math.cos(meanSlopeRadians(points, closed: closed));
    if (cosSlope < 1e-6) return 1;
    return 1 / cosSlope;
  }

  /// Área sobre el terreno a partir del área planimétrica en m².
  static double slopedArea(
    double planimetricAreaM2,
    List<GeoPoint> points,
  ) {
    return planimetricAreaM2 * slopeFactor(points, closed: true);
  }

  /// Desnivel total del recorrido en metros: subida acumulada [gain] y
  /// bajada acumulada [loss]. Sigue el camino capturado (sin cierre).
  static ({double gain, double loss}) elevationGainLoss(
    List<GeoPoint> points,
  ) {
    var gain = 0.0;
    var loss = 0.0;
    for (var i = 0; i < points.length - 1; i++) {
      final delta = points[i + 1].altitude - points[i].altitude;
      if (delta > 0) {
        gain += delta;
      } else {
        loss -= delta;
      }
    }
    return (gain: gain, loss: loss);
  }

  /// Diferencia entre la altitud máxima y mínima en metros.
  /// Retorna 0 sin puntos.
  static double altitudeRange(List<GeoPoint> points) {
    if (points.isEmpty) return 0;
    var min = points.first.altitude;
    var max = points.first.altitude;
    for (final point in points) {
      if (point.altitude < min) min = point.altitude;
      if (point.altitude > max) max = point.altitude;
    }
    return max - min;
  }

  /// `true` si el terreno se considera plano (desnivel menor a [tolerance]).
  static bool isFlat(
    List<GeoPoint> points, {
    double tolerance = 2.0,
  }) {
    return altitudeRange(points) < tolerance;
  }
}
