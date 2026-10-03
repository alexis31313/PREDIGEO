import 'dart:math' as math;
import '../entities/coordinate.dart';

/// Caso de uso que calcula el área de un polígono definido por coordenadas GPS.
class CalculateAreaUsecase {
  /// Calcula el área en metros cuadrados usando la fórmula de Gauss (shoelace).
  /// Requiere al menos 3 coordenadas para formar un polígono válido.
  Future<double> call(List<Coordinate> coordinates) async {
    if (coordinates.length < 3) {
      throw ArgumentError('Se requieren al menos 3 coordenadas para calcular el área.');
    }

    double area = 0.0;
    final int n = coordinates.length;

    for (int i = 0; i < n; i++) {
      final Coordinate current = coordinates[i];
      final Coordinate next = coordinates[(i + 1) % n];

      final double x1 = _longitudeToMeters(current.longitude, current.latitude);
      final double y1 = _latitudeToMeters(current.latitude);
      final double x2 = _longitudeToMeters(next.longitude, next.latitude);
      final double y2 = _latitudeToMeters(next.latitude);

      area += (x1 * y2) - (x2 * y1);
    }

    return (area.abs()) / 2.0;
  }

  double _latitudeToMeters(double latitude) {
    return latitude * 111320.0;
  }

  double _longitudeToMeters(double longitude, double latitude) {
    return longitude * 111320.0 * math.cos(latitude * math.pi / 180.0);
  }
}
