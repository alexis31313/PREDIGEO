import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:predigeo/domain/entities/geo_point.dart';
import 'package:predigeo/domain/usecases/geo/area_calculator.dart';
import 'package:predigeo/domain/usecases/geo/point2d.dart';

void main() {
  const double mocoaLat = 1.15;
  const double mocoaLon = -76.65;
  const double metersPerDegree = 111320.0;
  const double earthRadius = 6371000.0;

  final baseTime = DateTime(2026, 3, 15, 10, 30);

  GeoPoint geoPoint(double lat, double lon) {
    return GeoPoint(
      seq: 0,
      latitude: lat,
      longitude: lon,
      altitude: 1800.0,
      accuracy: 5.0,
      timestamp: baseTime,
    );
  }

  double toRadians(double degrees) => degrees * math.pi / 180.0;

  double haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = toRadians(lat2 - lat1);
    final dLon = toRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(toRadians(lat1)) *
            math.cos(toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double shoelaceArea(List<Point2D> points) {
    if (points.length < 3) return 0.0;
    var sum = 0.0;
    for (var i = 0; i < points.length; i++) {
      final j = (i + 1) % points.length;
      sum += points[i].x * points[j].y - points[j].x * points[i].y;
    }
    return sum.abs() / 2.0;
  }

  double haversineEnuArea(List<GeoPoint> points) {
    if (points.length < 3) return 0.0;
    final lat0 = points.first.latitude;
    final lon0 = points.first.longitude;
    final enu = points.map((p) {
      final east = haversineDistance(lat0, lon0, lat0, p.longitude);
      final signedEast = p.longitude >= lon0 ? east : -east;
      final north = haversineDistance(lat0, lon0, p.latitude, lon0);
      final signedNorth = p.latitude >= lat0 ? north : -north;
      return Point2D(signedEast, signedNorth);
    }).toList();
    return shoelaceArea(enu);
  }

  group('AreaCalculator.shoelace', () {
    test('cuadrado de 100x100 m → 10000 m² (1 ha)', () {
      final area = AreaCalculator.shoelace(const [
        Point2D(0, 0),
        Point2D(100, 0),
        Point2D(100, 100),
        Point2D(0, 100),
      ]);

      expect(area, closeTo(10000.0, 1e-6));
    });

    test('rectángulo de 50x200 m → 10000 m²', () {
      final area = AreaCalculator.shoelace(const [
        Point2D(0, 0),
        Point2D(200, 0),
        Point2D(200, 50),
        Point2D(0, 50),
      ]);

      expect(area, closeTo(10000.0, 1e-6));
    });

    test('triángulo de base 100 y altura 50 → 2500 m²', () {
      final area = AreaCalculator.shoelace(const [
        Point2D(0, 0),
        Point2D(100, 0),
        Point2D(0, 50),
      ]);

      expect(area, closeTo(2500.0, 1e-6));
    });

    test('polígono cóncavo → 15000 m²', () {
      final area = AreaCalculator.shoelace(const [
        Point2D(0, 0),
        Point2D(200, 0),
        Point2D(200, 100),
        Point2D(100, 50),
        Point2D(0, 100),
      ]);

      expect(area, closeTo(15000.0, 1e-6));
    });

    test('lista vacía → 0', () {
      expect(AreaCalculator.shoelace(const []), 0);
    });

    test('un solo punto → 0', () {
      expect(AreaCalculator.shoelace(const [Point2D(10, 10)]), 0);
    });
  });

  group('AreaCalculator.fromGeoPoints', () {
    test('cuadrado cerca de Mocoa coincide con la referencia geodésica (error < 0.5%)', () {
      final dLat = 100.0 / metersPerDegree;
      final dLon = 100.0 / (metersPerDegree * math.cos(toRadians(mocoaLat)));
      final square = [
        geoPoint(mocoaLat, mocoaLon),
        geoPoint(mocoaLat, mocoaLon + dLon),
        geoPoint(mocoaLat + dLat, mocoaLon + dLon),
        geoPoint(mocoaLat + dLat, mocoaLon),
      ];

      final area = AreaCalculator.fromGeoPoints(square);
      final reference = haversineEnuArea(square);

      final error = (area - reference).abs() / reference;
      expect(error, lessThan(0.005));
    });

    test('triángulo cerca de Mocoa coincide con la referencia geodésica (error < 0.5%)', () {
      final dLat = 100.0 / metersPerDegree;
      final dLon = 100.0 / (metersPerDegree * math.cos(toRadians(mocoaLat)));
      final triangle = [
        geoPoint(mocoaLat, mocoaLon),
        geoPoint(mocoaLat + dLat, mocoaLon),
        geoPoint(mocoaLat, mocoaLon + dLon),
      ];

      final area = AreaCalculator.fromGeoPoints(triangle);
      final reference = haversineEnuArea(triangle);

      final error = (area - reference).abs() / reference;
      expect(error, lessThan(0.005));
    });

    test('lista vacía → 0', () {
      expect(AreaCalculator.fromGeoPoints(const []), 0);
    });

    test('un solo punto → 0', () {
      expect(AreaCalculator.fromGeoPoints([geoPoint(mocoaLat, mocoaLon)]), 0);
    });
  });

  group('AreaCalculator.perimeter', () {
    test('cuadrado de 100x100 m → 400 m', () {
      final perimeter = AreaCalculator.perimeter(const [
        Point2D(0, 0),
        Point2D(100, 0),
        Point2D(100, 100),
        Point2D(0, 100),
      ]);

      expect(perimeter, closeTo(400.0, 1e-6));
    });

    test('rectángulo de 50x200 m → 500 m', () {
      final perimeter = AreaCalculator.perimeter(const [
        Point2D(0, 0),
        Point2D(200, 0),
        Point2D(200, 50),
        Point2D(0, 50),
      ]);

      expect(perimeter, closeTo(500.0, 1e-6));
    });
  });
}
