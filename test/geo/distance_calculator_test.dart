import 'package:flutter_test/flutter_test.dart';
import 'package:predigeo/domain/entities/geo_point.dart';
import 'package:predigeo/domain/usecases/geo/distance_calculator.dart';

void main() {
  final baseTime = DateTime(2026, 3, 15, 10, 30);

  GeoPoint point(
    double latitude,
    double longitude, {
    int seq = 0,
  }) {
    return GeoPoint(
      seq: seq,
      latitude: latitude,
      longitude: longitude,
      altitude: 0,
      accuracy: 5.0,
      timestamp: baseTime,
    );
  }

  group('DistanceCalculator.haversine', () {
    test('1° de latitud equivale aproximadamente a 111.19 km', () {
      final distance = DistanceCalculator.haversine(
        point(0, 0),
        point(1, 0),
      );

      expect(distance, closeTo(111194.93, 1.0));
    });

    test('distancia nula entre puntos idénticos', () {
      expect(
        DistanceCalculator.haversine(point(1.15, -76.65), point(1.15, -76.65)),
        closeTo(0.0, 1e-9),
      );
    });

    test('simetría: la distancia A→B es igual a B→A', () {
      final a = point(1.15380, -76.65100);
      final b = point(1.15390, -76.65090);

      expect(
        DistanceCalculator.haversine(a, b),
        closeTo(DistanceCalculator.haversine(b, a), 1e-9),
      );
    });
  });

  group('DistanceCalculator.vincenty', () {
    test('1° de longitud en el ecuador ronda 111.32 km', () {
      final distance = DistanceCalculator.vincenty(
        point(0, 0),
        point(0, 1),
      );

      expect(distance, closeTo(111319.49, 50.0));
    });

    test('Haversine y Vincenty difieren menos del 0.5 %', () {
      final a = point(0, 0);
      final b = point(0, 1);

      final haversine = DistanceCalculator.haversine(a, b);
      final vincenty = DistanceCalculator.vincenty(a, b);

      final relativeError = (haversine - vincenty).abs() / vincenty;
      expect(relativeError, lessThan(0.005));
    });

    test('respaldo a Haversine con puntos iguales sin fallar', () {
      expect(
        DistanceCalculator.vincenty(point(1.15, -76.65), point(1.15, -76.65)),
        closeTo(0.0, 1e-9),
      );
    });
  });

  group('DistanceCalculator.pathLength y perimeter', () {
    test('trayecto abierto suma los segmentos consecutivos', () {
      final points = [
        point(0, 0, seq: 0),
        point(0, 1, seq: 1),
        point(0, 2, seq: 2),
      ];

      final expected = DistanceCalculator.haversine(point(0, 0), point(0, 1)) +
          DistanceCalculator.haversine(point(0, 1), point(0, 2));

      expect(
        DistanceCalculator.pathLength(points),
        closeTo(expected, 1e-6),
      );
    });

    test('perímetro cierra el polígono', () {
      final points = [
        point(0, 0, seq: 0),
        point(0, 1, seq: 1),
        point(1, 1, seq: 2),
        point(1, 0, seq: 3),
      ];

      final open = DistanceCalculator.pathLength(points);
      final closening = DistanceCalculator.haversine(point(1, 0), point(0, 0));

      expect(
        DistanceCalculator.perimeter(points),
        closeTo(open + closening, 1e-6),
      );
    });

    test('menos de dos puntos devuelve 0', () {
      expect(DistanceCalculator.pathLength(const []), 0.0);
      expect(DistanceCalculator.pathLength([point(1, 1)]), 0.0);
      expect(DistanceCalculator.perimeter(const []), 0.0);
      expect(DistanceCalculator.perimeter([point(1, 1)]), 0.0);
    });
  });
}
