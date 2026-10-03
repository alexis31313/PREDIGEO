import '../errors/exceptions.dart';

/// Utilidades de validación para PrediGeo.
/// Proporciona métodos estáticos para validar coordenadas, polígonos y mediciones.
class Validators {
  Validators._();

  /// Valida que una latitud esté en el rango válido [-90, 90].
  /// Retorna true si es válida, lanza ValidationException en caso contrario.
  static bool isValidLatitude(double lat) {
    if (lat < -90.0 || lat > 90.0) {
      throw ValidationException(
        'La latitud debe estar entre -90 y 90 grados. Valor recibido: $lat',
      );
    }
    return true;
  }

  /// Valida que una longitud esté en el rango válido [-180, 180].
  /// Retorna true si es válida, lanza ValidationException en caso contrario.
  static bool isValidLongitude(double lon) {
    if (lon < -180.0 || lon > 180.0) {
      throw ValidationException(
        'La longitud debe estar entre -180 y 180 grados. Valor recibido: $lon',
      );
    }
    return true;
  }

  /// Valida que una altitud esté en un rango razonable [-500, 9000] metros.
  /// Retorna true si es válida, lanza ValidationException en caso contrario.
  static bool isValidAltitude(double alt) {
    if (alt < -500.0 || alt > 9000.0) {
      throw ValidationException(
        'La altitud debe estar entre -500 y 9000 metros. Valor recibido: $alt',
      );
    }
    return true;
  }

  /// Valida una coordenada completa (latitud, longitud, altitud).
  /// Retorna true si todos los valores son válidos.
  static bool isValidCoordinate(double lat, double lon, double alt) {
    isValidLatitude(lat);
    isValidLongitude(lon);
    isValidAltitude(alt);
    return true;
  }

  /// Valida que un polígono tenga al menos 3 puntos.
  /// Retorna true si la cantidad es suficiente, lanza ValidationException en caso contrario.
  static bool validatePolygonPointCount(int count) {
    if (count < 3) {
      throw ValidationException(
        'Se requieren al menos 3 puntos para formar un polígono. Puntos recibidos: $count',
      );
    }
    return true;
  }

  /// Valida que el nombre de una medición no esté vacío y tenga longitud adecuada.
  /// Retorna true si el nombre es válido, lanza ValidationException en caso contrario.
  static bool validateMeasurementName(String name) {
    if (name.trim().isEmpty) {
      throw ValidationException('El nombre de la medición no puede estar vacío');
    }
    if (name.trim().length < 3) {
      throw ValidationException(
        'El nombre de la medición debe tener al menos 3 caracteres',
      );
    }
    if (name.trim().length > 100) {
      throw ValidationException(
        'El nombre de la medición no puede exceder los 100 caracteres',
      );
    }
    return true;
  }
}
