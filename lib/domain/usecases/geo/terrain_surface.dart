// Calcula la superficie de terreno (malla TIN) a partir de los puntos GNSS
// capturados durante una medición, sin depender de red ni de DEM externas.

import 'dart:math' as math;

import '../../entities/geo_point.dart';
import 'geo_projector.dart';
import 'point2d.dart';

/// Tipo de superficie derivada del track de captura.
enum TerrainSurfaceKind { polygon, track, unavailable }

/// Superficie de terreno calculada localmente a partir de los puntos GNSS.
class TerrainSurface {
  final TerrainSurfaceKind kind;
  final List<GeoPoint> vertices;
  final List<List<GeoPoint>> triangles;
  final String? reason;

  TerrainSurface({
    required this.kind,
    required this.vertices,
    required this.triangles,
    this.reason,
  });

  /// `true` cuando hay una malla TIN lista para renderizar.
  bool get isAvailable =>
      kind == TerrainSurfaceKind.polygon && triangles.isNotEmpty;
}

/// Calculadora de superficies de terreno a partir de los puntos capturados.
class TerrainSurfaceCalculator {
  TerrainSurfaceCalculator();

  /// Umbral de precisión horizontal usado para descartar puntos poco fiables.
  static const double defaultMaxAccuracy = 20.0;

  /// Calcula la superficie de terreno para el track de [points].
  ///
  /// Devuelve un [TerrainSurface] de tipo polígono cuando hay suficientes
  /// puntos no colineales; tipo [TerrainSurfaceKind.track] cuando solo hay dos
  /// puntos (fallback a línea/trayecto) y tipo [TerrainSurfaceKind.unavailable]
  /// cuando no hay datos utilizables.
  TerrainSurface fromPoints(
    List<GeoPoint> points, {
    double maxAccuracy = defaultMaxAccuracy,
  }) {
    final valid = <GeoPoint>[];
    for (final point in points) {
      if (point.accuracy <= maxAccuracy &&
          point.altitude.isFinite &&
          !valid.any(
            (existing) =>
                existing.latitude == point.latitude &&
                existing.longitude == point.longitude,
          )) {
        valid.add(point);
      }
    }

    if (valid.isEmpty) {
      return TerrainSurface(
        kind: TerrainSurfaceKind.unavailable,
        vertices: const [],
        triangles: const [],
        reason: 'Sin puntos válidos. '
            'No se obtuvieron puntos válidos. '
            'Verifique la señal GPS y la precisión (max 20 m).',
      );
    }

    if (valid.length < 3) {
      final kind = valid.length == 2
          ? TerrainSurfaceKind.track
          : TerrainSurfaceKind.unavailable;
      return TerrainSurface(
        kind: kind,
        vertices: List<GeoPoint>.of(valid),
        triangles: const [],
        reason: kind == TerrainSurfaceKind.track ? null : 'Se necesitan al menos 3 puntos no alineados.',
      );
    }

    final centroid = _centroid(valid);
    final projected = GeoProjector(centroid).projectList(valid);
    if (_isCollinear(projected)) {
      return TerrainSurface(
        kind: TerrainSurfaceKind.unavailable,
        vertices: const [],
        triangles: const [],
        reason: 'Los puntos están alineados o coincidentes (colineales). '
            'Camine y capture puntos en diferentes ubicaciones.',
      );
    }

    final minAltitude =
        valid.map((point) => point.altitude).reduce((a, b) => a < b ? a : b);
    final surfaceVertices = <GeoPoint>[
      for (final point in valid)
        point.copyWith(altitude: point.altitude - minAltitude),
    ];

    final triangles = _delaunayTriangles(surfaceVertices, projected);

    return TerrainSurface(
      kind: TerrainSurfaceKind.polygon,
      vertices: surfaceVertices,
      triangles: triangles,
      reason: null,
    );
  }

  GeoPoint _centroid(List<GeoPoint> points) {
    var latSum = 0.0;
    var lonSum = 0.0;
    for (final point in points) {
      latSum += point.latitude;
      lonSum += point.longitude;
    }
    return GeoPoint(
      seq: 0,
      latitude: latSum / points.length,
      longitude: lonSum / points.length,
      altitude: 0,
      accuracy: 0,
      timestamp: points.first.timestamp,
    );
  }

  bool _isCollinear(List<Point2D> points) {
    if (points.length < 3) return true;
    // Verificar si todos los puntos son coincidentes.
    var allSame = true;
    for (var i = 1; i < points.length; i++) {
      if ((points[i].x - points[0].x).abs() > 1e-9 ||
          (points[i].y - points[0].y).abs() > 1e-9) {
        allSame = false;
        break;
      }
    }
    if (allSame) return true;
    final p0 = points[0];
    var p1 = points[1];
    var maxDistanceSquared = 0.0;
    for (final point in points.skip(1)) {
      final dx = point.x - p0.x;
      final dy = point.y - p0.y;
      final distanceSquared = dx * dx + dy * dy;
      if (distanceSquared > maxDistanceSquared) {
        maxDistanceSquared = distanceSquared;
        p1 = point;
      }
    }
    if (maxDistanceSquared == 0) return true;

    for (final point in points) {
      final cross =
          (p1.x - p0.x) * (point.y - p0.y) - (p1.y - p0.y) * (point.x - p0.x);
      if (cross.abs() >= 1e-6) return false;
    }
    return true;
  }

  List<List<GeoPoint>> _delaunayTriangles(
    List<GeoPoint> points,
    List<Point2D> projected,
  ) {
    final indexTriangles = _delaunay(projected);
    final triangles = <List<GeoPoint>>[];
    for (final t in indexTriangles) {
      final height = (points[t[0]].altitude +
              points[t[1]].altitude +
              points[t[2]].altitude) /
          3;
      if (height.isFinite) {
        triangles.add(<GeoPoint>[points[t[0]], points[t[1]], points[t[2]]]);
      }
    }
    triangles.sort((a, b) {
      for (var i = 0; i < 3; i++) {
        final cmp = a[i].seq.compareTo(b[i].seq);
        if (cmp != 0) return cmp;
      }
      return 0;
    });
    return triangles;
  }

  /// Delaunay (Bowyer-Watson) sobre el plano proyectado a metros.
  List<List<int>> _delaunay(List<Point2D> pts) {
    final n = pts.length;
    var minX = pts[0].x;
    var maxX = pts[0].x;
    var minY = pts[0].y;
    var maxY = pts[0].y;
    for (final p in pts) {
      minX = math.min(minX, p.x);
      maxX = math.max(maxX, p.x);
      minY = math.min(minY, p.y);
      maxY = math.max(maxY, p.y);
    }
    final cx = (minX + maxX) / 2;
    final cy = (minY + maxY) / 2;
    final big = math.max(math.max(maxX - minX, maxY - minY), 1.0) * 1e6;
    final coords = List<Point2D>.filled(n + 3, const Point2D(0, 0));
    for (var i = 0; i < n; i++) {
      coords[i] = pts[i];
    }
    coords[n] = Point2D(cx - big, cy - big);
    coords[n + 1] = Point2D(cx + big, cy - big);
    coords[n + 2] = Point2D(cx, cy + big);

    var tris = <List<int>>[
      [n, n + 1, n + 2]
    ];
    for (var i = 0; i < n; i++) {
      final bad = <List<int>>[];
      final kept = <List<int>>[];
      for (final t in tris) {
        if (_inCircle(coords[t[0]], coords[t[1]], coords[t[2]], coords[i])) {
          bad.add(t);
        } else {
          kept.add(t);
        }
      }
      tris = kept;
      final edgeCounts = <String, int>{};
      final edges = <String, List<int>>{};
      for (final t in bad) {
        for (final e in <List<int>>[
          <int>[t[0], t[1]],
          <int>[t[1], t[2]],
          <int>[t[2], t[0]],
        ]) {
          final a = e[0] < e[1] ? e[0] : e[1];
          final b = e[0] < e[1] ? e[1] : e[0];
          final key = '$a,$b';
          edgeCounts.update(key, (count) => count + 1, ifAbsent: () => 1);
          edges[key] = <int>[a, b];
        }
      }
      for (final entry in edgeCounts.entries) {
        if (entry.value != 1) continue;
        final e = edges[entry.key]!;
        tris.add(<int>[e[0], e[1], i]);
      }
    }
    return tris.where((t) {
      if (t[0] >= n || t[1] >= n || t[2] >= n) return false;
      final a = coords[t[0]];
      final b = coords[t[1]];
      final c = coords[t[2]];
      final twiceArea = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
      return twiceArea.abs() > 1e-10;
    }).toList(growable: false);
  }

  bool _inCircle(Point2D a, Point2D b, Point2D c, Point2D p) {
    final ax = a.x - p.x;
    final ay = a.y - p.y;
    final bx = b.x - p.x;
    final by = b.y - p.y;
    final cx = c.x - p.x;
    final cy = c.y - p.y;
    final determinant = (ax * ax + ay * ay) * (bx * cy - cx * by) -
        (bx * bx + by * by) * (ax * cy - cx * ay) +
        (cx * cx + cy * cy) * (ax * by - bx * ay);
    final orientation = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
    return orientation > 0 ? determinant >= -1e-12 : determinant <= 1e-12;
  }
}
