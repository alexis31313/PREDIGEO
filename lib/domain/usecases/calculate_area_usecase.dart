import 'dart:math' as math;

import '../entities/geo_point.dart';

/// Caso de uso que calcula el área de un polígono definido por puntos GNSS.
///
/// Utiliza la fórmula de Gauss (shoelace) proyectando las coordenadas geodésicas
/// a un plano local en metros, con el primer vértice como origen. La proyección
/// es válida para los polígonos de terreno (decenas de metros a pocos
/// kilómetros), donde la curvatura terrestre no introduce errores apreciables.
class CalculateAreaUsecase {
  static const double _metersPerDegree = 111320.0;

  /// Calcula el área en metros cuadrados.
  /// Lanza [ArgumentError] si se requieren menos de tres puntos.
  Future<double> call(List<GeoPoint> points) async {
    if (points.length < 3) {
      throw ArgumentError(
        'Se requieren al menos 3 puntos para calcular el área.',
      );
    }

    final origin = points.first;
    var twiceArea = 0.0;

    for (var i = 0; i < points.length; i++) {
      final current = points[i];
      final next = points[(i + 1) % points.length];

      final x1 = _eastMeters(origin, current);
      final y1 = _northMeters(origin, current);
      final x2 = _eastMeters(origin, next);
      final y2 = _northMeters(origin, next);

      twiceArea += (x1 * y2) - (x2 * y1);
    }

    return twiceArea.abs() / 2.0;
  }

  /// Desplazamiento en metros hacia el Este respecto al origen local.
  double _eastMeters(GeoPoint origin, GeoPoint point) {
    final scale = _metersPerDegree * math.cos(_toRadians(point.latitude));
    return scale * (point.longitude - origin.longitude);
  }

  /// Desplazamiento en metros hacia el Norte respecto al origen local.
  double _northMeters(GeoPoint origin, GeoPoint point) {
    return _metersPerDegree * (point.latitude - origin.latitude);
  }

  double _toRadians(double degrees) => degrees * math.pi / 180.0;
}