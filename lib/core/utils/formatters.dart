import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

/// Utilidades de formato para PrediGeo.
/// Proporciona métodos estáticos para formatear áreas, distancias, coordenadas,
/// fechas y precisiones GPS.
class Formatters {
  Formatters._();

  /// Formatea un área en metros cuadrados a una cadena legible.
  /// Muestra el valor en m² y su equivalente en hectáreas.
  /// Ejemplo: "1500.50 m² (0.15 ha)"
  static String formatArea(double squareMeters) {
    final hectares = squareMeters / 10000.0;
    return '${squareMeters.toStringAsFixed(2)} m² (${hectares.toStringAsFixed(2)} ha)';
  }

  /// Formatea una distancia en metros a una cadena legible.
  /// Muestra el valor en metros o kilómetros según la magnitud.
  /// Ejemplo: "1500.50 m" o "1.50 km"
  static String formatDistance(double meters) {
    if (meters >= 1000.0) {
      final kilometers = meters / 1000.0;
      return '${kilometers.toStringAsFixed(2)} km';
    }
    return '${meters.toStringAsFixed(2)} m';
  }

  /// Formatea un valor de coordenada con la cantidad de decimales especificada.
  /// Ejemplo: formatCoordinate(-33.4567, 6) -> "-33.456700"
  static String formatCoordinate(double value, int decimals) {
    return value.toStringAsFixed(decimals);
  }

  /// Formatea una fecha al formato definido en la aplicación.
  /// Ejemplo: "25/12/2024 14:30"
  static String formatDate(DateTime date) {
    final formatter = DateFormat(AppConstants.dateFormat);
    return formatter.format(date);
  }

  /// Formatea un valor de precisión GPS con una etiqueta de calidad.
  /// Retorna 'Excelente' (<= 5m), 'Buena' (<= 10m), 'Regular' (<= 20m) o 'Mala' (> 20m).
  static String formatAccuracy(double accuracy) {
    if (accuracy <= 5.0) {
      return 'Excelente';
    } else if (accuracy <= 10.0) {
      return 'Buena';
    } else if (accuracy <= 20.0) {
      return 'Regular';
    } else {
      return 'Mala';
    }
  }
}
