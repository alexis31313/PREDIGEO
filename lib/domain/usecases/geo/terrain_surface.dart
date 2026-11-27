// Calcula la superficie de terreno (malla TIN) a partir de los puntos GNSS
// capturados durante una medición, sin depender de red ni de DEM externas.

import 'dart:math' as math;

import '../../entities/geo_point.dart';
import 'geo_projector.dart';
import 'point2d.dart';

/// Tipo de superficie derivada del track de captura.
enum TerrainSurfaceKind { polygon, track, unavailable }

/// Punto 3D en un sistema local métrico: `x` hacia el este, `y` hacia el
/// norte y `z` hacia arriba (todos en metros).
class TerrainPoint3 {
  final double x;
  final double y;
  final double z;

  const TerrainPoint3(this.x, this.y, this.z);

  @override
  String toString() => 'TerrainPoint3($x, $y, $z)';
}

/// Superficie de terreno calculada localmente a partir de los puntos GNSS.
///
/// Además de los vértices geográficos ([vertices]) y los triángulos
/// ([triangles]) expone la misma malla en coordenadas locales en metros
/// ([local]) y como índices ([triangleIndices]), que es lo que consume el
/// renderizado 3D.
class TerrainSurface {
  final TerrainSurfaceKind kind;

  /// Vértices válidos con la altitud relativa (el más bajo queda en 0).
  final List<GeoPoint> vertices;

  /// Triángulos de la malla TIN, expresados con los mismos objetos de
  /// [vertices].
  final List<List<GeoPoint>> triangles;

  /// Motivo por el que no hay superficie disponible (si aplica).
  final String? reason;

  /// Coordenadas locales en metros de cada vértice (mismo orden que
  /// [vertices]). `z` es la altitud relativa.
  final List<TerrainPoint3> local;

  /// Triángulos como índices sobre [vertices] / [local].
  final List<List<int>> triangleIndices;

  /// Etiqueta corta de cada vértice: "1", "2"... para el contorno e
  /// "I1", "I2"... para los puntos interiores.
  final List<String> labels;

  /// `true` para los vértices que provienen del muestreo interior.
  final List<bool> isInterior;

  /// Altitud real (m) que corresponde a `z = 0`.
  final double baseAltitude;

  /// Contorno del área en coordenadas locales (vacío si no aplica).
  final List<Point2D> boundary;

  TerrainSurface._internal({
    required this.kind,
    required this.vertices,
    required this.triangles,
    required this.reason,
    required this.local,
    required this.triangleIndices,
    required this.labels,
    required this.isInterior,
    required this.baseAltitude,
    required this.boundary,
  });

  /// Crea una superficie. Los campos derivados ([local], [triangleIndices],
  /// [labels], [isInterior]) se calculan a partir de [vertices] y
  /// [triangles] cuando no se proporcionan.
  factory TerrainSurface({
    required TerrainSurfaceKind kind,
    required List<GeoPoint> vertices,
    required List<List<GeoPoint>> triangles,
    String? reason,
    List<TerrainPoint3>? local,
    List<List<int>>? triangleIndices,
    List<String>? labels,
    List<bool>? isInterior,
    double baseAltitude = 0,
    List<Point2D> boundary = const <Point2D>[],
  }) {
    final resolvedLocal = local ?? _localFromVertices(vertices);
    final resolvedIndices =
        triangleIndices ?? _indicesFromTriangles(vertices, triangles);
    return TerrainSurface._internal(
      kind: kind,
      vertices: vertices,
      triangles: triangles,
      reason: reason,
      local: resolvedLocal,
      triangleIndices: resolvedIndices,
      labels: labels ??
          <String>[for (final v in vertices) '${v.seq + 1}'],
      isInterior: isInterior ?? List<bool>.filled(vertices.length, false),
      baseAltitude: baseAltitude,
      boundary: boundary,
    );
  }

  /// `true` cuando hay una malla TIN lista para renderizar.
  bool get isAvailable =>
      kind == TerrainSurfaceKind.polygon && triangles.isNotEmpty;

  /// Desnivel (m) entre el vértice más alto y el más bajo.
  double get altitudeRange {
    if (local.isEmpty) return 0;
    var min = local.first.z;
    var max = local.first.z;
    for (final p in local) {
      min = math.min(min, p.z);
      max = math.max(max, p.z);
    }
    return max - min;
  }

  static List<TerrainPoint3> _localFromVertices(List<GeoPoint> vertices) {
    if (vertices.isEmpty) return const <TerrainPoint3>[];
    final projector = GeoProjector(geoCentroid(vertices));
    return <TerrainPoint3>[
      for (final v in vertices)
        () {
          final p = projector.project(v);
          return TerrainPoint3(p.x, p.y, v.altitude);
        }(),
    ];
  }

  static List<List<int>> _indicesFromTriangles(
    List<GeoPoint> vertices,
    List<List<GeoPoint>> triangles,
  ) {
    final result = <List<int>>[];
    for (final t in triangles) {
      final idx = <int>[for (final p in t) vertices.indexOf(p)];
      if (idx.length == 3 && !idx.contains(-1)) result.add(idx);
    }
    return result;
  }
}

/// Centroide (lat/lon promedio) de una lista de puntos no vacía.
GeoPoint geoCentroid(List<GeoPoint> points) {
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

/// `true` si [p] está dentro del polígono [polygon] (regla par-impar).
bool pointInPolygon(Point2D p, List<Point2D> polygon) {
  var inside = false;
  for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    final a = polygon[i];
    final b = polygon[j];
    if ((a.y > p.y) != (b.y > p.y)) {
      final xCross = (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x;
      if (p.x < xCross) inside = !inside;
    }
  }
  return inside;
}

/// Calculadora de superficies de terreno a partir de los puntos capturados.
class TerrainSurfaceCalculator {
  TerrainSurfaceCalculator();

  /// Umbral de precisión horizontal usado para descartar puntos poco fiables.
  static const double defaultMaxAccuracy = 20.0;

  /// Calcula la superficie de terreno para el track de [points].
  ///
  /// [points] son los puntos del contorno (o del trayecto) e
  /// [interiorPoints] los puntos muestreados dentro del área. Cuando
  /// [clipToBoundary] es `true` y hay al menos 3 puntos de contorno, los
  /// triángulos cuyo centro cae fuera del polígono del contorno se descartan
  /// (evita triángulos "puente" en áreas cóncavas).
  ///
  /// Devuelve un [TerrainSurface] de tipo polígono cuando hay suficientes
  /// puntos no colineales; tipo [TerrainSurfaceKind.track] cuando solo hay dos
  /// puntos (fallback a línea/trayecto) y tipo [TerrainSurfaceKind.unavailable]
  /// cuando no hay datos utilizables.
  TerrainSurface fromPoints(
    List<GeoPoint> points, {
    double maxAccuracy = defaultMaxAccuracy,
    List<GeoPoint> interiorPoints = const <GeoPoint>[],
    bool clipToBoundary = false,
  }) {
    final valid = <GeoPoint>[];
    final interiorFlags = <bool>[];
    final labels = <String>[];
    void consider(GeoPoint point, bool interior, String label) {
      if (point.accuracy <= maxAccuracy &&
          point.altitude.isFinite &&
          point.latitude.isFinite &&
          point.longitude.isFinite &&
          !valid.any(
            (existing) =>
                existing.latitude == point.latitude &&
                existing.longitude == point.longitude,
          )) {
        valid.add(point);
        interiorFlags.add(interior);
        labels.add(label);
      }
    }

    for (final point in points) {
      consider(point, false, '${point.seq + 1}');
    }
    for (var i = 0; i < interiorPoints.length; i++) {
      consider(interiorPoints[i], true, 'I${i + 1}');
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
        reason: kind == TerrainSurfaceKind.track
            ? null
            : 'Se necesitan al menos 3 puntos no alineados.',
      );
    }

    final projector = GeoProjector(geoCentroid(valid));
    final projected = projector.projectList(valid);
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
    final local = <TerrainPoint3>[
      for (var i = 0; i < valid.length; i++)
        TerrainPoint3(
          projected[i].x,
          projected[i].y,
          surfaceVertices[i].altitude,
        ),
    ];

    final boundary = <Point2D>[
      for (final p in points)
        if (p.latitude.isFinite && p.longitude.isFinite) projector.project(p),
    ];

    var indices = _delaunay(projected);
    if (clipToBoundary && boundary.length >= 3) {
      final clipped = indices.where((t) {
        final cx = (projected[t[0]].x + projected[t[1]].x + projected[t[2]].x) / 3;
        final cy = (projected[t[0]].y + projected[t[1]].y + projected[t[2]].y) / 3;
        return pointInPolygon(Point2D(cx, cy), boundary);
      }).toList();
      // Si el recorte elimina todo (contorno ruidoso), se conserva la malla.
      if (clipped.isNotEmpty) indices = clipped;
    }

    indices.sort((a, b) {
      for (var i = 0; i < 3; i++) {
        final cmp = surfaceVertices[a[i]].seq.compareTo(surfaceVertices[b[i]].seq);
        if (cmp != 0) return cmp;
      }
      return 0;
    });

    final triangles = <List<GeoPoint>>[
      for (final t in indices)
        <GeoPoint>[
          surfaceVertices[t[0]],
          surfaceVertices[t[1]],
          surfaceVertices[t[2]],
        ],
    ];

    return TerrainSurface(
      kind: TerrainSurfaceKind.polygon,
      vertices: surfaceVertices,
      triangles: triangles,
      reason: null,
      local: local,
      triangleIndices: indices,
      labels: labels,
      isInterior: interiorFlags,
      baseAltitude: minAltitude,
      boundary: clipToBoundary ? boundary : const <Point2D>[],
    );
  }

  bool _isCollinear(List<Point2D> points) {
    if (points.length < 3) return true;
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
      final edgeCounts = <int, int>{};
      final edges = <int, List<int>>{};
      for (final t in bad) {
        for (final e in <List<int>>[
          <int>[t[0], t[1]],
          <int>[t[1], t[2]],
          <int>[t[2], t[0]],
        ]) {
          final a = e[0] < e[1] ? e[0] : e[1];
          final b = e[0] < e[1] ? e[1] : e[0];
          final key = a * (n + 3) + b;
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
    }).toList();
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
