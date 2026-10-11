import '../../entities/gps_reading.dart';
import '../../../core/utils/geo_utils.dart';

/// Filtro de valores atípicos para lecturas GPS.
/// Elimina lecturas con precisión insuficiente y lecturas cuya velocidad
/// implícita respecto a la lectura anterior supere el umbral permitido.
class OutlierFilter {
  final double maxAccuracy;
  final double maxSpeed;

  /// Crea un filtro de valores atípicos.
  /// [maxAccuracy] es la precisión horizontal máxima permitida en metros (por defecto 20.0).
  /// [maxSpeed] es la velocidad máxima permitida en m/s (por defecto 15.0).
  OutlierFilter({
    this.maxAccuracy = 20.0,
    this.maxSpeed = 15.0,
  });

  /// Filtra una lista de lecturas GPS, descartando las que no pasan el filtro.
  /// Retorna una nueva lista con las lecturas válidas.
  List<GpsReading> filter(List<GpsReading> readings) {
    final validReadings = <GpsReading>[];
    GpsReading? previous;

    for (final reading in readings) {
      if (filterSingle(reading, previous)) {
        validReadings.add(reading);
        previous = reading;
      }
    }

    return validReadings;
  }

  /// Evalúa si una lectura individual pasa el filtro.
  /// Retorna true si la lectura es válida y false si debe descartarse.
  /// [reading] es la lectura a evaluar.
  /// [previous] es la lectura válida anterior (null si es la primera).
  bool filterSingle(GpsReading reading, GpsReading? previous) {
    if (reading.horizontalAccuracy > maxAccuracy) {
      return false;
    }

    if (previous != null) {
      final distance = GeoUtils.haversineDistance(
        previous.latitude,
        previous.longitude,
        reading.latitude,
        reading.longitude,
      );

      final timeDiff =
          reading.timestamp.difference(previous.timestamp).inMilliseconds.abs();

      if (timeDiff > 0) {
        final impliedSpeed = distance / (timeDiff / 1000.0);
        if (impliedSpeed > maxSpeed) {
          return false;
        }
      }
    }

    return true;
  }
}
