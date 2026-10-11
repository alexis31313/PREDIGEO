import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:predigeo/domain/entities/geo_point.dart';
import 'package:predigeo/domain/usecases/geo/geo_projector.dart';
import 'package:predigeo/domain/usecases/geo/point2d.dart';

void main() {
  const double mocoaLat = 1.15;
  const double mocoaLon = -76.65;
  const double metersPerDegree = 111320.0;
  const double wgs84EquatorialRadius = 6378137.0;

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
    double radius,
  ) {
    final dLat = toRadians(lat2 - lat1);
    final dLon = toRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(toRadians(lat1)) *
            math.cos(toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return radius * c;
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

  double haversineEnuArea(List<GeoPoint> points, double radius) {
    if (points.length < 3) return 0.0;
    final lat0 = points.first.latitude;
    final lon0 = points.first.longitude;
    final enu = points.map((p) {
      final east = haversineDistance(lat0, lon0, lat0, p.longitude, radius);
      final signedEast = p.longitude >= lon0 ? east : -east;
      final north = haversineDistance(lat0, lon0, p.latitude, lon0, radius);
      final signedNorth = p.latitude >= lat0 ? north : -north;
      return Point2D(signedEast, signedNorth);
    }).toList();
    return shoelaceArea(enu);
  }

  group('GeoProjector.project', () {
    test('convierte el origen en (0, 0)', () {
      final origin = geoPoint(mocoaLat, mocoaLon);
      final projector = GeoProjector(origin);

      final projected = projector.project(origin);

      expect(projected.x, closeTo(0.0, 1e-9));
      expect(projected.y, closeTo(0.0, 1e-9));
    });

    test('convierte un punto 0.001° al norte en ~111.32 m', () {
      final projector = GeoProjector(geoPoint(mocoaLat, mocoaLon));

      final projected = projector.project(geoPoint(mocoaLat + 0.001, mocoaLon));

      expect(projected.y, closeTo(111.32, 0.25));
      expect(projected.x, closeTo(0.0, 1e-9));
    });

    test('convierte un punto 0.001° al este en ~111.32 m × cos(lat)', () {
      final projector = GeoProjector(geoPoint(mocoaLat, mocoaLon));
      final expectedEast = 111.32 * math.cos(toRadians(mocoaLat));

      final projected = projector.project(geoPoint(mocoaLat, mocoaLon + 0.001));

      expect(projected.x, closeTo(expectedEast, 0.25));
      expect(projected.y, closeTo(0.0, 1e-9));
    });
  });

  group('GeoProjector.projectList', () {
    test('devuelve la misma cantidad de puntos que la entrada', () {
      final projector = GeoProjector(geoPoint(mocoaLat, mocoaLon));
      final points = [
        geoPoint(mocoaLat, mocoaLon),
        geoPoint(mocoaLat + 0.001, mocoaLon),
        geoPoint(mocoaLat + 0.001, mocoaLon + 0.001),
        geoPoint(mocoaLat, mocoaLon + 0.001),
        geoPoint(mocoaLat - 0.0005, mocoaLon + 0.0005),
      ];

      final projected = projector.projectList(points);

      expect(projected.length, points.length);
      expect(
          projected.first.x, closeTo(projector.project(points.first).x, 1e-9));
      expect(
          projected.first.y, closeTo(projector.project(points.first).y, 1e-9));
    });
  });

  group('GeoProjector: propiedad de 100 ha', () {
    test('el error del área proyectada es menor al 0.1%', () {
      final origin = geoPoint(mocoaLat, mocoaLon);
      final projector = GeoProjector(origin);

      final dLat = 1000.0 / metersPerDegree;
      final dLon = 1000.0 / (metersPerDegree * math.cos(toRadians(mocoaLat)));

      final corners = [
        geoPoint(mocoaLat, mocoaLon),
        geoPoint(mocoaLat, mocoaLon + dLon),
        geoPoint(mocoaLat + dLat, mocoaLon + dLon),
        geoPoint(mocoaLat + dLat, mocoaLon),
      ];

      final area = shoelaceArea(projector.projectList(corners));
      final reference = haversineEnuArea(corners, wgs84EquatorialRadius);

      final error = (area - reference).abs() / reference;
      expect(error, lessThan(0.001));
      expect(area, closeTo(1000000.0, 10.0));
    });
  });
}
