import 'package:flutter_test/flutter_test.dart';
import 'package:predigeo/domain/entities/geo_point.dart';
import 'package:predigeo/domain/usecases/geo/terrain_surface.dart';

void main() {
  final baseTime = DateTime(2026, 3, 15, 10, 30);

  GeoPoint point({
    required double altitude,
    double accuracy = 5.0,
    int seq = 0,
    double? latitude,
    double longitude = -76.65100,
  }) {
    return GeoPoint(
      seq: seq,
      latitude: latitude ?? 1.15380 + seq * 0.0001,
      longitude: longitude,
      altitude: altitude,
      accuracy: accuracy,
      timestamp: baseTime.add(Duration(seconds: seq)),
    );
  }

  final calculator = TerrainSurfaceCalculator();

  double twiceArea(GeoPoint a, GeoPoint b, GeoPoint c) {
    return (b.latitude - a.latitude) * (c.longitude - a.longitude) -
        (b.longitude - a.longitude) * (c.latitude - a.latitude);
  }

  void expectNoDegenerateTriangles(TerrainSurface surface) {
    final vertices = surface.vertices.toSet();
    for (final triangle in surface.triangles) {
      expect(triangle, hasLength(3));
      expect(triangle.every(vertices.contains), isTrue);
      expect(
        twiceArea(triangle[0], triangle[1], triangle[2]).abs(),
        greaterThan(1e-14),
      );
    }
  }

  group('TerrainSurfaceCalculator.fromPoints', () {
    test('devuelve una malla TIN para un polígono de 3 puntos', () {
      final surface = calculator.fromPoints([
        point(altitude: 430, seq: 0, latitude: 1.15380, longitude: -76.65100),
        point(altitude: 435, seq: 1, latitude: 1.15390, longitude: -76.65100),
        point(altitude: 428, seq: 2, latitude: 1.15390, longitude: -76.65090),
      ]);

      expect(
        surface.isAvailable,
        isTrue,
        reason:
            '${surface.kind}: ${surface.reason}, ${surface.triangles.length} triangles',
      );
      expect(surface.kind, TerrainSurfaceKind.polygon);
      expect(surface.vertices.length, 3);
      expect(surface.triangles.length, 1);
      expect(surface.triangles.first.length, 3);
    });

    test('devuelve una malla TIN para un polígono de 4 puntos', () {
      final surface = calculator.fromPoints([
        point(altitude: 430, seq: 0, latitude: 1.15380, longitude: -76.65100),
        point(altitude: 435, seq: 1, latitude: 1.15390, longitude: -76.65100),
        point(altitude: 428, seq: 2, latitude: 1.15390, longitude: -76.65090),
        point(altitude: 432, seq: 3, latitude: 1.15380, longitude: -76.65090),
      ]);

      expect(surface.isAvailable, isTrue);
      expect(surface.kind, TerrainSurfaceKind.polygon);
      expect(surface.vertices.length, 4);
      expect(surface.triangles.length, 2);
      expect(surface.triangles.every((t) => t.length == 3), isTrue);
      expectNoDegenerateTriangles(surface);

      final usedSeqs = <int>{};
      for (final t in surface.triangles) {
        for (final p in t) {
          usedSeqs.add(p.seq);
        }
      }
      expect(usedSeqs.length, 4);
    });

    test('triangula 4 puntos con uno interior en 3 triángulos', () {
      final surface = calculator.fromPoints([
        point(altitude: 430, seq: 0, latitude: 1.15380, longitude: -76.65100),
        point(altitude: 435, seq: 1, latitude: 1.15380, longitude: -76.65070),
        point(altitude: 428, seq: 2, latitude: 1.15410, longitude: -76.65100),
        point(altitude: 432, seq: 3, latitude: 1.15390, longitude: -76.65090),
      ]);

      expect(surface.isAvailable, isTrue);
      expect(surface.triangles, hasLength(3));
      expectNoDegenerateTriangles(surface);
      expect(
        surface.triangles
            .expand((triangle) => triangle)
            .map((p) => p.seq)
            .toSet(),
        {0, 1, 2, 3},
      );
    });

    test('elimina puntos duplicados antes de triangular', () {
      final surface = calculator.fromPoints([
        point(altitude: 430, seq: 0, latitude: 1.15380, longitude: -76.65100),
        point(altitude: 435, seq: 1, latitude: 1.15380, longitude: -76.65090),
        point(altitude: 428, seq: 2, latitude: 1.15390, longitude: -76.65100),
        point(altitude: 432, seq: 3, latitude: 1.15380, longitude: -76.65100),
      ]);

      expect(surface.vertices, hasLength(3));
      expect(surface.triangles, hasLength(1));
      expectNoDegenerateTriangles(surface);
    });

    test('triangula puntos casi colineales sin triángulos degenerados', () {
      final surface = calculator.fromPoints([
        point(altitude: 430, seq: 0, latitude: 1.15380, longitude: -76.65100),
        point(altitude: 435, seq: 1, latitude: 1.15390, longitude: -76.650999),
        point(altitude: 428, seq: 2, latitude: 1.15400, longitude: -76.6509989),
        point(altitude: 432, seq: 3, latitude: 1.15410, longitude: -76.65100),
      ]);

      expect(
        surface.isAvailable,
        isTrue,
        reason:
            '${surface.kind}: ${surface.reason}, ${surface.triangles.length} triangles',
      );
      expect(surface.triangles, isNotEmpty);
      expectNoDegenerateTriangles(surface);
    });

    test('cubre el casco convexo con 12 puntos dispersos sin huecos', () {
      final points = [
        point(altitude: 430, seq: 0, latitude: 1.15380, longitude: -76.65100),
        point(altitude: 431, seq: 1, latitude: 1.15380, longitude: -76.65000),
        point(altitude: 432, seq: 2, latitude: 1.15480, longitude: -76.65100),
        point(altitude: 433, seq: 3, latitude: 1.15480, longitude: -76.65000),
        point(altitude: 434, seq: 4, latitude: 1.15400, longitude: -76.65080),
        point(altitude: 435, seq: 5, latitude: 1.15410, longitude: -76.65030),
        point(altitude: 436, seq: 6, latitude: 1.15420, longitude: -76.65060),
        point(altitude: 437, seq: 7, latitude: 1.15440, longitude: -76.65020),
        point(altitude: 438, seq: 8, latitude: 1.15460, longitude: -76.65070),
        point(altitude: 439, seq: 9, latitude: 1.15470, longitude: -76.65040),
        point(altitude: 440, seq: 10, latitude: 1.15430, longitude: -76.65090),
        point(altitude: 441, seq: 11, latitude: 1.15450, longitude: -76.65050),
      ];

      final surface = calculator.fromPoints(points);
      final coveredArea = surface.triangles
          .map((triangle) =>
              twiceArea(triangle[0], triangle[1], triangle[2]).abs() / 2)
          .fold<double>(0, (sum, area) => sum + area);
      final usedSeqs = surface.triangles
          .expand((triangle) => triangle)
          .map((p) => p.seq)
          .toSet();

      expect(surface.isAvailable, isTrue);
      expect(surface.triangles, hasLength(18));
      expect(usedSeqs, points.map((p) => p.seq).toSet());
      expect(coveredArea, closeTo(1e-6, 1e-12));
      expectNoDegenerateTriangles(surface);
    });

    test('normaliza las alturas sin valores negativos', () {
      final surface = calculator.fromPoints([
        point(altitude: 431, seq: 0, latitude: 1.15380, longitude: -76.65100),
        point(altitude: -10, seq: 1, latitude: 1.15390, longitude: -76.65100),
        point(altitude: 5, seq: 2, latitude: 1.15390, longitude: -76.65090),
      ]);
      final heights = [
        ...surface.vertices.map((vertex) => vertex.altitude),
        ...surface.triangles
            .expand((triangle) => triangle)
            .map((p) => p.altitude),
      ];

      expect(
        surface.vertices
            .map((vertex) => vertex.altitude)
            .reduce((a, b) => a < b ? a : b),
        0,
      );
      expect(heights.every((height) => height >= 0), isTrue);
    });

    test('devuelve una malla TIN para un polígono de 6 puntos', () {
      final surface = calculator.fromPoints([
        point(altitude: 430, seq: 0, latitude: 1.15380, longitude: -76.65100),
        point(altitude: 435, seq: 1, latitude: 1.15390, longitude: -76.65100),
        point(altitude: 437, seq: 2, latitude: 1.15395, longitude: -76.65095),
        point(altitude: 428, seq: 3, latitude: 1.15390, longitude: -76.65090),
        point(altitude: 431, seq: 4, latitude: 1.15385, longitude: -76.65095),
        point(altitude: 429, seq: 5, latitude: 1.15380, longitude: -76.65090),
      ]);

      expect(surface.isAvailable, isTrue);
      expect(surface.vertices.length, 6);
      expect(surface.triangles.length, greaterThanOrEqualTo(1));
      expect(surface.triangles.every((t) => t.length == 3), isTrue);
    });

    test('devuelve tipo track (fallback) cuando solo hay dos puntos', () {
      final surface = calculator.fromPoints([
        point(altitude: 430, seq: 0, latitude: 1.15380, longitude: -76.65100),
        point(altitude: 435, seq: 1, latitude: 1.15390, longitude: -76.65100),
      ]);

      expect(surface.kind, TerrainSurfaceKind.track);
      expect(surface.isAvailable, isFalse);
      expect(surface.vertices.length, 2);
      expect(surface.triangles, isEmpty);
    });

    test('devuelve unavailable cuando los puntos son colineales', () {
      final surface = calculator.fromPoints([
        point(altitude: 430, seq: 0, latitude: 1.15380, longitude: -76.65100),
        point(altitude: 432, seq: 1, latitude: 1.15381, longitude: -76.65100),
        point(altitude: 428, seq: 2, latitude: 1.15382, longitude: -76.65100),
      ]);

      expect(surface.kind, TerrainSurfaceKind.unavailable);
      expect(surface.isAvailable, isFalse);
      expect(surface.triangles, isEmpty);
      expect(surface.reason, contains('colineal'));
    });

    test('devuelve unavailable cuando no quedan puntos con precisión valida',
        () {
      final surface = calculator.fromPoints([
        point(altitude: 430, seq: 0, accuracy: 30.0),
        point(altitude: 432, seq: 1, accuracy: 30.0),
      ]);

      expect(surface.kind, TerrainSurfaceKind.unavailable);
      expect(surface.isAvailable, isFalse);
      expect(surface.reason, contains('puntos válidos'));
    });

    test('descarta puntos cuya altitud no es valida', () {
      final surface = calculator.fromPoints([
        point(
            altitude: double.nan,
            seq: 0,
            latitude: 1.15380,
            longitude: -76.65100),
        point(altitude: 430, seq: 1, latitude: 1.15390, longitude: -76.65100),
        point(altitude: 432, seq: 2, latitude: 1.15390, longitude: -76.65090),
      ]);

      // El punto con altitud NaN se descarta; quedan dos puntos validos.
      expect(surface.kind, TerrainSurfaceKind.track);
      expect(surface.vertices.length, 2);
    });
  });
}
