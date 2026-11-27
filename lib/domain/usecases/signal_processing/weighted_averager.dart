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

    for (final reading in readings) {
      final weight =
          1.0 / (reading.horizontalAccuracy * reading.horizontalAccuracy);
      sumWeights += weight;
      weightedLat += reading.latitude * weight;
      weightedLon += reading.longitude * weight;
    }

    final avgLat = weightedLat / sumWeights;
    final avgLon = weightedLon / sumWeights;
    final estimatedAccuracy = 1.0 / _sqrt(sumWeights);
    final (avgAlt, altAccuracy) = robustAltitude(readings);

    final latestTimestamp =
        readings.map((r) => r.timestamp).reduce((a, b) => a.isAfter(b) ? a : b);

    return GpsReading(
      latitude: avgLat,
      longitude: avgLon,
      altitude: avgAlt,
      horizontalAccuracy: estimatedAccuracy,
      altitudeAccuracy: altAccuracy ?? estimatedAccuracy,
      speed: 0.0,
      timestamp: latestTimestamp,
    );
  }

  /// Calcula un promedio simple de las lecturas (sin ponderación).
  GpsReading _simpleAverage(List<GpsReading> readings) {
    double sumLat = 0.0;
    double sumLon = 0.0;

    for (final reading in readings) {
      sumLat += reading.latitude;
      sumLon += reading.longitude;
    }

    final count = readings.length.toDouble();
    final latestTimestamp =
        readings.map((r) => r.timestamp).reduce((a, b) => a.isAfter(b) ? a : b);

    return GpsReading(
      latitude: sumLat / count,
      longitude: sumLon / count,
      altitude: robustAltitude(readings).$1,
      horizontalAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      speed: 0.0,
      timestamp: latestTimestamp,
    );
  }

  /// Estima la altitud de un conjunto de lecturas de forma robusta.
  ///
  /// 1. Descarta las altitudes atípicas: las que se alejan de la mediana más
  ///    de 3 desviaciones robustas (1,4826 · MAD), con un margen mínimo de
  ///    2 m para no descartar ruido normal.
  /// 2. Promedia las restantes ponderando por 1/σ² con la precisión
  ///    **vertical** (`altitudeAccuracy`). Si el dispositivo no la reporta, se
  ///    usa la horizontal y, si tampoco hay, un promedio simple.
  ///
  /// Devuelve la altitud y su precisión estimada (`null` si no hay datos de
  /// precisión vertical).
  static (double, double?) robustAltitude(List<GpsReading> readings) {
    final valid = readings.where((r) => r.altitude.isFinite).toList();
    if (valid.isEmpty) return (double.nan, null);
    if (valid.length == 1) {
      final acc = valid.first.altitudeAccuracy;
      return (valid.first.altitude, acc > 0 ? acc : null);
    }

    final median = _median(valid.map((r) => r.altitude).toList());
    var kept = valid;
    if (valid.length >= 3) {
      final mad = _median(
        valid.map((r) => (r.altitude - median).abs()).toList(),
      );
      final limit = (3 * 1.4826 * mad) < 2.0 ? 2.0 : 3 * 1.4826 * mad;
      final filtered =
          valid.where((r) => (r.altitude - median).abs() <= limit).toList();
      if (filtered.isNotEmpty) kept = filtered;
    }

    final useVertical = kept.every((r) => r.altitudeAccuracy > 0);
    final useHorizontal =
        !useVertical && kept.every((r) => r.horizontalAccuracy > 0);
    var sumW = 0.0;
    var sumAlt = 0.0;
    for (final r in kept) {
      final sigma = useVertical
          ? r.altitudeAccuracy
          : (useHorizontal ? r.horizontalAccuracy : 1.0);
      final w = 1.0 / (sigma * sigma);
      sumW += w;
      sumAlt += r.altitude * w;
    }
    return (sumAlt / sumW, useVertical ? 1.0 / _sqrt(sumW) : null);
  }

  static double _median(List<double> values) {
    final sorted = List<double>.of(values)..sort();
    final mid = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[mid]
        : (sorted[mid - 1] + sorted[mid]) / 2;
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
