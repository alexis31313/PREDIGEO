import '../../entities/gps_reading.dart';

/// Promediador ponderado para lecturas GPS.
/// Calcula el promedio de las lecturas usando 1/accuracy² como peso,
/// otorgando mayor influencia a las lecturas más precisas.
class WeightedAverager {
  const WeightedAverager();

  /// Calcula el promedio ponderado de una lista de lecturas GPS.
  /// Retorna un GpsReading con las coordenadas promediadas y la precisión estimada.
  /// Lanza ArgumentError si la lista está vacía.
  /// Si todas las precisiones son cero, utiliza un promedio simple.
  GpsReading average(List<GpsReading> readings) {
    if (readings.isEmpty) {
      throw ArgumentError(
          'No se puede calcular el promedio de una lista vacía');
    }

    bool allZeroAccuracy = readings.every(
      (r) => r.horizontalAccuracy == 0,
    );

    if (allZeroAccuracy) {
      return _simpleAverage(readings);
    }

    double sumWeights = 0.0;
    double weightedLat = 0.0;
    double weightedLon = 0.0;
    double weightedAlt = 0.0;

    for (final reading in readings) {
      final weight =
          1.0 / (reading.horizontalAccuracy * reading.horizontalAccuracy);
      sumWeights += weight;
      weightedLat += reading.latitude * weight;
      weightedLon += reading.longitude * weight;
      weightedAlt += reading.altitude * weight;
    }

    final avgLat = weightedLat / sumWeights;
    final avgLon = weightedLon / sumWeights;
    final avgAlt = weightedAlt / sumWeights;
    final estimatedAccuracy = 1.0 / _sqrt(sumWeights);

    final latestTimestamp =
        readings.map((r) => r.timestamp).reduce((a, b) => a.isAfter(b) ? a : b);

    return GpsReading(
      latitude: avgLat,
      longitude: avgLon,
      altitude: avgAlt,
      horizontalAccuracy: estimatedAccuracy,
      altitudeAccuracy: estimatedAccuracy,
      speed: 0.0,
      timestamp: latestTimestamp,
    );
  }

  /// Calcula un promedio simple de las lecturas (sin ponderación).
  GpsReading _simpleAverage(List<GpsReading> readings) {
    double sumLat = 0.0;
    double sumLon = 0.0;
    double sumAlt = 0.0;

    for (final reading in readings) {
      sumLat += reading.latitude;
      sumLon += reading.longitude;
      sumAlt += reading.altitude;
    }

    final count = readings.length.toDouble();
    final latestTimestamp =
        readings.map((r) => r.timestamp).reduce((a, b) => a.isAfter(b) ? a : b);

    return GpsReading(
      latitude: sumLat / count,
      longitude: sumLon / count,
      altitude: sumAlt / count,
      horizontalAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      speed: 0.0,
      timestamp: latestTimestamp,
    );
  }

  /// Calcula la raíz cuadrada de un número usando el método de Newton-Raphson.
  static double _sqrt(double value) {
    if (value < 0) return 0;
    if (value == 0) return 0;
    double x = value;
    double y = (x + 1) / 2;
    while ((x - y).abs() > 1e-10) {
      x = y;
      y = (x + value / x) / 2;
    }
    return y;
  }
}
