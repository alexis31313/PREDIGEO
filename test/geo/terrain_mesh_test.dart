import 'package:flutter_test/flutter_test.dart';
import 'package:predigeo/domain/entities/geo_point.dart';
import 'package:predigeo/domain/usecases/geo/point2d.dart';
import 'package:predigeo/domain/usecases/geo/terrain_mesh.dart';
import 'package:predigeo/domain/usecases/geo/terrain_surface.dart';

import '../support/fixtures.dart';

void main() {
  final calculator = TerrainSurfaceCalculator();

  // Cuadrado de ~44 m con un punto interior 10 m más alto.
  List<GeoPoint> contour() => <GeoPoint>[
        buildPoint(seq: 0, latitude: 1.15380, longitude: -76.65100, altitude: 430),
        buildPoint(seq: 1, latitude: 1.15380, longitude: -76.65060, altitude: 431),
        buildPoint(seq: 2, latitude: 1.15420, longitude: -76.65060, altitude: 433),
        buildPoint(seq: 3, latitude: 1.15420, longitude: -76.65100, altitude: 432),
      ];
  final interior = <GeoPoint>[
    buildPoint(seq: 0, latitude: 1.15400, longitude: -76.65080, altitude: 440),
  ];

  group('TerrainSurface (coordenadas locales y recorte)', () {
    test('expone coordenadas en metros, etiquetas y altitud base', () {
      final surface = calculator.fromPoints(
        contour(),
        interiorPoints: interior,
        clipToBoundary: true,
      );

      expect(surface.isAvailable, isTrue);
      expect(surface.baseAltitude, 430);
      expect(surface.altitudeRange, closeTo(10, 1e-9));
      expect(surface.labels, ['1', '2', '3', '4', 'I1']);
      expect(surface.isInterior, [false, false, false, false, true]);
      // ~0.0004° ≈ 44 m en el ecuador.
      final xs = surface.local.map((p) => p.x);
      final width = xs.reduce((a, b) => a > b ? a : b) -
          xs.reduce((a, b) => a < b ? a : b);
      expect(width, closeTo(44.5, 1.0));
      expect(surface.triangleIndices, hasLength(surface.triangles.length));
    });

    test('recorta los triángulos fuera de un contorno cóncavo (forma de L)',
        () {
      // L: falta el cuadrante noreste.
      final l = <GeoPoint>[
        buildPoint(seq: 0, latitude: 1.15380, longitude: -76.65100),
        buildPoint(seq: 1, latitude: 1.15380, longitude: -76.65060),
        buildPoint(seq: 2, latitude: 1.15400, longitude: -76.65060),
        buildPoint(seq: 3, latitude: 1.15400, longitude: -76.65080),
        buildPoint(seq: 4, latitude: 1.15420, longitude: -76.65080),
        buildPoint(seq: 5, latitude: 1.15420, longitude: -76.65100),
      ];
      final unclipped = calculator.fromPoints(l);
      final clipped = calculator.fromPoints(l, clipToBoundary: true);

      expect(clipped.triangles.length, lessThan(unclipped.triangles.length));
      for (final t in clipped.triangleIndices) {
        final cx = (clipped.local[t[0]].x +
                clipped.local[t[1]].x +
                clipped.local[t[2]].x) /
            3;
        final cy = (clipped.local[t[0]].y +
                clipped.local[t[1]].y +
                clipped.local[t[2]].y) /
            3;
        expect(pointInPolygon(Point2D(cx, cy), clipped.boundary), isTrue);
      }
    });
  });

  group('TerrainMesh', () {
    test('sin subdivisión reproduce el TIN y su borde', () {
      final surface = calculator.fromPoints(contour(), interiorPoints: interior);
      final mesh = TerrainMesh.fromSurface(surface);

      expect(mesh.triangleCount, 4);
      expect(mesh.vertexCount, 5);
      expect(mesh.boundaryEdges.length ~/ 2, 4);
      expect(mesh.dataVertices, hasLength(5));
      expect(mesh.dataLabels, contains('I1'));
    });

    test('todos los triángulos quedan en sentido antihorario', () {
      final surface = calculator.fromPoints(contour(), interiorPoints: interior);
      final mesh = TerrainMesh.fromSurface(surface, subdivisions: 3);
      for (var t = 0; t < mesh.triangles.length; t += 3) {
        final a = mesh.triangles[t], b = mesh.triangles[t + 1];
        final c = mesh.triangles[t + 2];
        final cross = (mesh.xs[b] - mesh.xs[a]) * (mesh.ys[c] - mesh.ys[a]) -
            (mesh.ys[b] - mesh.ys[a]) * (mesh.xs[c] - mesh.xs[a]);
        expect(cross, greaterThan(0));
      }
    });

    test('la subdivisión multiplica los triángulos y conserva los datos', () {
      final surface = calculator.fromPoints(contour(), interiorPoints: interior);
      final mesh = TerrainMesh.fromSurface(surface, subdivisions: 4);

      expect(mesh.triangleCount, 4 * 16);
      // Los vértices medidos no se mueven con el suavizado.
      for (var i = 0; i < surface.local.length; i++) {
        expect(mesh.zs[i], surface.local[i].z);
      }
      // El borde sigue siendo un solo anillo: 4 lados × 4 segmentos.
      expect(mesh.boundaryEdges.length ~/ 2, 16);
      // El suavizado no sale del rango de altitudes medido.
      expect(mesh.minZ, greaterThanOrEqualTo(0));
      expect(mesh.maxZ, lessThanOrEqualTo(10));
    });

    test('elige intervalos de curvas redondos', () {
      expect(TerrainMesh.niceContourStep(10), 2);
      expect(TerrainMesh.niceContourStep(3), 0.5);
      expect(TerrainMesh.niceContourStep(120), 20);
      expect(TerrainMesh.niceContourStep(0), 0);
    });

    test('genera curvas de nivel a la altitud correcta', () {
      final surface = calculator.fromPoints(contour(), interiorPoints: interior);
      final mesh = TerrainMesh.fromSurface(surface);
      final segments = mesh.contours(2);

      expect(segments, isNotEmpty);
      final levels = segments.map((s) => s.z + mesh.baseAltitude).toSet();
      for (final level in levels) {
        expect(level % 2, closeTo(0, 1e-9));
        expect(level, inInclusiveRange(430, 440));
      }
      expect(segments.any((s) => s.isIndex), isTrue); // 430 y 440
    });
  });
}
