import 'dart:math';

import '../constants/app_constants.dart';

/// Utilidades de cálculo geodésico para PrediGeo.
/// Incluye métodos estáticos para distancias, áreas, perímetros y errores.
class GeoUtils {
  GeoUtils._();

  /// Calcula la distancia geodésica entre dos puntos usando la fórmula de Haversine.
  /// Retorna la distancia en metros.
  static double haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = degreesToRadians(lat2 - lat1);
    final dLon = degreesToRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(degreesToRadians(lat1)) *
            cos(degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return AppConstants.earthRadius * c;
  }

  /// Calcula el área de un polígono usando la fórmula del zapatero (shoelace)
  /// con conversión a coordenadas ENU (Este, Norte, Arriba).
  /// Retorna el área en metros cuadrados.
  static double calculatePolygonArea(List<double> lats, List<double> lons) {
    if (lats.length < AppConstants.minPolygonPoints ||
        lons.length < AppConstants.minPolygonPoints) {
      throw ArgumentError(
        'Se requieren al menos ${AppConstants.minPolygonPoints} puntos para calcular el área',
      );
    }

    if (lats.length != lons.length) {
      throw ArgumentError(
        'Las listas de latitudes y longitudes deben tener la misma longitud',
      );
    }

    final enuCoords = _convertToEnu(lats, lons);
    double area = 0.0;
    final n = enuCoords.length;

    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      area += enuCoords[i].east * enuCoords[j].north;
      area -= enuCoords[j].east * enuCoords[i].north;
    }

    return (area / 2.0).abs();
  }

  /// Calcula el perímetro de un polígono sumando las distancias entre puntos consecutivos.
  /// Retorna el perímetro en metros.
  static double calculatePerimeter(List<double> lats, List<double> lons) {
    if (lats.length < 2 || lons.length < 2) {
      throw ArgumentError(
        'Se requieren al menos 2 puntos para calcular el perímetro',
      );
    }

    if (lats.length != lons.length) {
      throw ArgumentError(
        'Las listas de latitudes y longitudes deben tener la misma longitud',
      );
    }

    double perimeter = 0.0;
    for (int i = 0; i < lats.length - 1; i++) {
      perimeter +=
          haversineDistance(lats[i], lons[i], lats[i + 1], lons[i + 1]);
    }

    perimeter += haversineDistance(
      lats.last,
      lons.last,
      lats.first,
      lons.first,
    );

    return perimeter;
  }

  /// Calcula el Error Cuadrático Medio (RMSE) entre valores medidos y de referencia.
  /// Retorna el RMSE como un valor double.
  static double calculateRMSE(
    List<double> measured,
    List<double> reference,
  ) {
    if (measured.length != reference.length) {
      throw ArgumentError(
        'Las listas de valores medidos y de referencia deben tener la misma longitud',
      );
    }

    if (measured.isEmpty) {
      throw ArgumentError('Las listas no pueden estar vacías');
    }

    double sumSquaredErrors = 0.0;
    for (int i = 0; i < measured.length; i++) {
      final error = measured[i] - reference[i];
      sumSquaredErrors += error * error;
    }

    return sqrt(sumSquaredErrors / measured.length);
  }

  /// Calcula el error absoluto entre un valor medido y uno de referencia.
  /// Retorna el valor absoluto de la diferencia.
  static double calculateAbsoluteError(double measured, double reference) {
    return (measured - reference).abs();
  }

  /// Calcula el error porcentual entre un valor medido y uno de referencia.
  /// Retorna el error como porcentaje (0-100).
  static double calculatePercentError(double measured, double reference) {
    if (reference == 0) {
      throw ArgumentError(
        'El valor de referencia no puede ser cero para calcular error porcentual',
      );
    }

    return ((measured - reference).abs() / reference.abs()) * 100.0;
  }

  /// Convierte grados a radianes.
  static double degreesToRadians(double degrees) {
    return degrees * (pi / 180.0);
  }

  /// Convierte radianes a grados.
  static double radiansToDegrees(double radians) {
    return radians * (180.0 / pi);
  }

  /// Convierte coordenadas geodésicas (latitud, longitud) a coordenadas ENU
  /// (Este, Norte, Arriba) usando el primer punto como origen local.
  static List<_EnuCoordinate> _convertToEnu(
    List<double> lats,
    List<double> lons,
  ) {
    final originLat = lats.first;
    final originLon = lons.first;

    final enuCoords = <_EnuCoordinate>[];

    for (int i = 0; i < lats.length; i++) {
      final east = haversineDistance(originLat, originLon, originLat, lons[i]);
      final signedEast = lons[i] >= originLon ? east : -east;

      final north = haversineDistance(originLat, originLon, lats[i], originLon);
      final signedNorth = lats[i] >= originLat ? north : -north;

      enuCoords.add(_EnuCoordinate(signedEast, signedNorth));
    }

    return enuCoords;
  }
}

/// Representa una coordenada en el sistema ENU (Este, Norte, Arriba).
class _EnuCoordinate {
  final double east;
  final double north;

  _EnuCoordinate(this.east, this.north);
}
