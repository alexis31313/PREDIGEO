import 'package:flutter_test/flutter_test.dart';
import 'package:predigeo/domain/entities/geo_point.dart';
import 'package:predigeo/domain/usecases/geo/distance_calculator.dart';
import 'package:predigeo/domain/usecases/geo/elevation_stats.dart';

void main() {
  final baseTime = DateTime(2026, 3, 15, 10, 30);

  GeoPoint point({
    required double altitude,
    double accuracy = 5.0,
    int seq = 0,
    double latitude = 1.15380,
    double longitude = -76.65100,
  }) {
    return GeoPoint(
      seq: seq,
      latitude: latitude + seq * 0.0001,
      longitude: longitude,
      altitude: altitude,
      accuracy: accuracy,
      timestamp: baseTime.add(Duration(seconds: seq)),
    );
  }

  group('ElevationStats.fromPoints', () {
    test('calcula min, max, promedio y desniveles con datos sintéticos', () {
      final points = [
        point(altitude: 100, seq: 0),
        point(altitude: 110, seq: 1),
        point(altitude: 105, seq: 2),
        point(altitude: 120, seq: 3),
        point(altitude: 90, seq: 4),
      ];

      final stats = ElevationStats.fromPoints(points);

      expect(stats.sampleCount, 5);
      expect(stats.ignoredCount, 0);
      expect(stats.minAltitude, 90);
      expect(stats.maxAltitude, 120);
      expect(stats.averageAltitude, closeTo(105.0, 1e-9));
      // Ascensos: +10 (100→110) y +15 (105→120) = 25.
      expect(stats.positiveGain, closeTo(25.0, 1e-9));
      // Descensos: -5 (110→105) y -30 (120→90) = 35.
      expect(stats.negativeGain, closeTo(35.0, 1e-9));
      expect(stats.altitudeRange, closeTo(30.0, 1e-9));
      expect(stats.hasData, isTrue);
    });

    test('la pendiente media es coherente con la distancia del recorrido', () {
      final points = [
        point(altitude: 100, seq: 0),
        point(altitude: 110, seq: 1),
      ];

      final stats = ElevationStats.fromPoints(points);
      final distance = DistanceCalculator.pathLength(points);
      final expectedSlope = (10.0 / distance) * 100.0;

      expect(stats.averageSlopePercent, isNotNull);
      expect(stats.averageSlopePercent!, closeTo(expectedSlope, 1e-6));
    });

    test('descarta los puntos de baja precisión', () {
      final points = [
        point(altitude: 100, accuracy: 5, seq: 0),
        point(altitude: 500, accuracy: 50, seq: 1),
        point(altitude: 104, accuracy: 5, seq: 2),
      ];

      final stats = ElevationStats.fromPoints(points, maxAccuracy: 20);

      expect(stats.sampleCount, 2);
      expect(stats.ignoredCount, 1);
      expect(stats.maxAltitude, 104);
    });

    test('lista vacía devuelve estadísticas vacías', () {
      final stats = ElevationStats.fromPoints(const []);

      expect(stats.sampleCount, 0);
      expect(stats.hasData, isFalse);
      expect(stats.minAltitude, isNull);
      expect(stats.averageSlopePercent, isNull);
    });

    test('un único punto no rompe y no acumula desnivel', () {
      final stats = ElevationStats.fromPoints([point(altitude: 200)]);

      expect(stats.sampleCount, 1);
      expect(stats.minAltitude, 200);
      expect(stats.maxAltitude, 200);
      expect(stats.averageAltitude, 200);
      expect(stats.positiveGain, 0);
      expect(stats.negativeGain, 0);
      expect(stats.averageSlopePercent, 0);
    });

    test('todos los puntos descartados deja el cálculo vacío', () {
      final stats = ElevationStats.fromPoints([
        point(altitude: 100, accuracy: 60),
        point(altitude: 200, accuracy: 80, seq: 1),
      ]);

      expect(stats.sampleCount, 0);
      expect(stats.ignoredCount, 2);
      expect(stats.hasData, isFalse);
    });
  });
}
