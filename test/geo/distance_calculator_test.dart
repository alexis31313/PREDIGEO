// Pruebas de DistanceCalculator: Haversine, Vincenty, trayecto y perímetro.
// Valores verificables a mano; tolerancia Haversine vs Vincenty < 0,5 %.

import 'package:flutter_test/flutter_test.dart';
import 'package:predigeo/domain/entities/geo_point.dart';
import 'package:predigeo/domain/usecases/geo/distance_calculator.dart';

void main() {
  final baseTime = DateTime(2026, 3, 15, 10, 30);

  GeoPoint point(double lat, double lon, [int seq = 0]) {
    return GeoPoint(
      seq: seq,
      latitude: lat,
      longitude: lon,
      altitude: 500.0,
      accuracy: 5.0,
      timestamp: baseTime,
    );
  }

  group('DistanceCalculator.haversine', () {
    test('1 grado de latitud ≈ 111,19 km (R * pi / 180)', () {
      // 6371000 * pi / 180 = 111194.9 m.
      final distance = DistanceCalculator.haversine(0, 0, 1, 0);
      expect(distance, closeTo(111194.9, 250.0));
    });

    test('puntos coincidentes → 0', () {
      expect(DistanceCalculator.haversine(1.15, -76.65, 1.15, -76.65), 0);
    });

    test('100 m al norte cerca de Mocoa', () {
      // 100 m ≈ 100 / 111320 grados de latitud.
      const mocoaLat = 1.15;
      const mocoaLon = -76.65;
      final distance = DistanceCalculator.haversine(
        mocoaLat,
        mocoaLon,
        mocoaLat + 100.0 / 111320.0,
        mocoaLon,
      );
      expect(distance, closeTo(100.0, 1.0));
    });
  });

  group('DistanceCalculator.vincenty', () {
    test('puntos coincidentes → 0', () {
      expect(DistanceCalculator.vincenty(1.15, -76.65, 1.15, -76.65), 0);
    });

    test('Haversine vs Vincenty difieren menos del 0,5 %', () {
      const pairs = [
        [1.15, -76.65, 1.16, -76.64],
        [1.15, -76.65, 1.151, -76.651],
        [4.711, -74.0721, 4.721, -74.0621],
        [0.0, 0.0, 1.0, 1.0],
      ];
      for (final pair in pairs) {
        final haversine = DistanceCalculator.haversine(
          pair[0],
          pair[1],
          pair[2],
          pair[3],
        );
        final vincenty = DistanceCalculator.vincenty(
          pair[0],
          pair[1],
          pair[2],
          pair[3],
        );
        expect(vincenty, greaterThan(0));
        expect(
          (haversine - vincenty).abs() / vincenty,
          lessThan(0.005),
        );
      }
    });
  });

  group('DistanceCalculator.pathLength', () {
    test('suma los tramos consecutivos', () {
      final points = [
        point(1.15, -76.65, 0),
        point(1.15 + 100.0 / 111320.0, -76.65, 1),
        point(1.15 + 200.0 / 111320.0, -76.65, 2),
      ];
      expect(DistanceCalculator.pathLength(points), closeTo(200.0, 2.0));
    });

    test('con 0 o 1 punto → 0', () {
      expect(DistanceCalculator.pathLength([]), 0);
      expect(DistanceCalculator.pathLength([point(1.15, -76.65)]), 0);
    });
  });

  group('DistanceCalculator.perimeter', () {
    test('cierra el polígono (cuadrado 100x100 → 400 m)', () {
      const lat = 1.15;
      const lon = -76.65;
      const side = 100.0 / 111320.0;
      final points = [
        point(lat, lon, 0),
        point(lat, lon + side, 1),
        point(lat + side, lon + side, 2),
        point(lat + side, lon, 3),
      ];
      expect(DistanceCalculator.perimeter(points), closeTo(400.0, 4.0));
    });

    test('con 0 o 1 punto → 0', () {
      expect(DistanceCalculator.perimeter([]), 0);
      expect(DistanceCalculator.perimeter([point(1.15, -76.65)]), 0);
    });
  });
}
