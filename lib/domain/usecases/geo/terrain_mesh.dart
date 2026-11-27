// Malla de renderizado derivada de una [TerrainSurface].
//
// Trabaja en coordenadas locales en metros (x = este, y = norte, z = altura
// relativa). Opcionalmente subdivide cada triángulo del TIN y suaviza los
// vértices nuevos para obtener un relieve más continuo, manteniendo fijos los
// puntos medidos (la superficie sigue pasando por los datos reales).

import 'dart:math' as math;
import 'dart:typed_data';

import 'terrain_surface.dart';

/// Segmento de curva de nivel en coordenadas locales.
class ContourSegment {
  final double x1, y1, x2, y2;

  /// Altura relativa (z) del segmento.
  final double z;

  /// Triángulo de la malla que contiene el segmento.
  final int triangle;

  /// `true` para las curvas maestras (cada 5 intervalos).
  final bool isIndex;

  const ContourSegment(
    this.x1,
    this.y1,
    this.x2,
    this.y2,
    this.z,
    this.triangle,
    this.isIndex,
  );
}

/// Malla triangular lista para dibujar.
class TerrainMesh {
  /// Coordenadas de los vértices (metros).
  final Float64List xs;
  final Float64List ys;
  final Float64List zs;

  /// Triángulos de la superficie superior, 3 índices por triángulo, todos en
  /// sentido antihorario visto desde arriba.
  final Int32List triangles;

  /// Aristas del borde (pares de índices) orientadas en el sentido del
  /// triángulo al que pertenecen: el exterior queda a la derecha.
  final Int32List boundaryEdges;

  /// Índices en la malla de los puntos medidos, con su etiqueta.
  final List<int> dataVertices;
  final List<String> dataLabels;
  final List<bool> dataInterior;

  /// Altitud real que corresponde a `z = 0`.
  final double baseAltitude;

  final double minX, maxX, minY, maxY, minZ, maxZ;

  TerrainMesh._({
    required this.xs,
    required this.ys,
    required this.zs,
    required this.triangles,
    required this.boundaryEdges,
    required this.dataVertices,
    required this.dataLabels,
    required this.dataInterior,
    required this.baseAltitude,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.minZ,
    required this.maxZ,
  });

  int get vertexCount => xs.length;
  int get triangleCount => triangles.length ~/ 3;

  double get centerX => (minX + maxX) / 2;
  double get centerY => (minY + maxY) / 2;
  double get spanX => maxX - minX;
  double get spanY => maxY - minY;
  double get altitudeRange => maxZ - minZ;

  /// Mayor dimensión horizontal (m), mínimo 1 m.
  double get horizontalExtent => math.max(math.max(spanX, spanY), 1.0);

  /// Construye la malla a partir de [surface].
  ///
  /// [subdivisions] = 1 reproduce el TIN original; valores mayores dividen
  /// cada triángulo en `subdivisions²` triángulos y aplican un suavizado
  /// laplaciano a los vértices nuevos (los medidos permanecen fijos).
  factory TerrainMesh.fromSurface(
    TerrainSurface surface, {
    int subdivisions = 1,
  }) {
    final n = math.max(1, subdivisions);
    final base = surface.local;
    final xs = <double>[for (final p in base) p.x];
    final ys = <double>[for (final p in base) p.y];
    final zs = <double>[for (final p in base) p.z];
    final originalCount = base.length;

    // Triángulos del TIN en sentido antihorario.
    final tin = <List<int>>[];
    for (final t in surface.triangleIndices) {
      final a = t[0], b = t[1], c = t[2];
      final cross = (xs[b] - xs[a]) * (ys[c] - ys[a]) -
          (ys[b] - ys[a]) * (xs[c] - xs[a]);
      if (cross.abs() < 1e-12) continue;
      tin.add(cross > 0 ? <int>[a, b, c] : <int>[a, c, b]);
    }

    final tris = <int>[];
    if (n == 1) {
      for (final t in tin) {
        tris.addAll(t);
      }
    } else {
      final keyToIndex = <String, int>{};
      int vertexFor(List<int> corners, int wa, int wb, int wc) {
        final weights = <int>[wa, wb, wc];
        for (var k = 0; k < 3; k++) {
          if (weights[k] == n) return corners[k];
        }
        final parts = <List<int>>[
          for (var k = 0; k < 3; k++)
            if (weights[k] > 0) <int>[corners[k], weights[k]],
        ]..sort((p, q) => p[0].compareTo(q[0]));
        final key = parts.map((p) => '${p[0]}:${p[1]}').join(',');
        final existing = keyToIndex[key];
        if (existing != null) return existing;
        final fa = wa / n, fb = wb / n, fc = wc / n;
        xs.add(xs[corners[0]] * fa + xs[corners[1]] * fb + xs[corners[2]] * fc);
        ys.add(ys[corners[0]] * fa + ys[corners[1]] * fb + ys[corners[2]] * fc);
        zs.add(zs[corners[0]] * fa + zs[corners[1]] * fb + zs[corners[2]] * fc);
        final index = xs.length - 1;
        keyToIndex[key] = index;
        return index;
      }

      for (final t in tin) {
        // grid[a][b] con a = peso de t[1], b = peso de t[2].
        final grid = List<List<int>>.generate(
          n + 1,
          (a) => List<int>.generate(
            n + 1 - a,
            (b) => vertexFor(t, n - a - b, a, b),
          ),
        );
        for (var a = 0; a < n; a++) {
          for (var b = 0; b < n - a; b++) {
            tris.addAll(<int>[grid[a][b], grid[a + 1][b], grid[a][b + 1]]);
            if (b < n - a - 1) {
              tris.addAll(
                <int>[grid[a + 1][b], grid[a + 1][b + 1], grid[a][b + 1]],
              );
            }
          }
        }
      }

      _smooth(zs, tris, originalCount, iterations: n * 2);
    }

    final boundary = _boundaryEdges(tris);

    var minX = double.infinity, maxX = double.negativeInfinity;
    var minY = double.infinity, maxY = double.negativeInfinity;
    var minZ = double.infinity, maxZ = double.negativeInfinity;
    for (var i = 0; i < xs.length; i++) {
      minX = math.min(minX, xs[i]);
      maxX = math.max(maxX, xs[i]);
      minY = math.min(minY, ys[i]);
      maxY = math.max(maxY, ys[i]);
      minZ = math.min(minZ, zs[i]);
      maxZ = math.max(maxZ, zs[i]);
    }
    if (xs.isEmpty) {
      minX = maxX = minY = maxY = minZ = maxZ = 0;
    }

    // Solo se etiquetan los puntos que forman parte de algún triángulo.
    final used = <int>{...tris.where((i) => i < originalCount)};
    final dataVertices = <int>[
      for (var i = 0; i < originalCount; i++)
        if (used.contains(i)) i,
    ];

    return TerrainMesh._(
      xs: Float64List.fromList(xs),
      ys: Float64List.fromList(ys),
      zs: Float64List.fromList(zs),
      triangles: Int32List.fromList(tris),
      boundaryEdges: Int32List.fromList(boundary),
      dataVertices: dataVertices,
      dataLabels: <String>[
        for (final i in dataVertices)
          i < surface.labels.length ? surface.labels[i] : '${i + 1}',
      ],
      dataInterior: <bool>[
        for (final i in dataVertices)
          i < surface.isInterior.length && surface.isInterior[i],
      ],
      baseAltitude: surface.baseAltitude,
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
      minZ: minZ,
      maxZ: maxZ,
    );
  }

  /// Suavizado laplaciano de las alturas, sin mover los vértices medidos.
  static void _smooth(
    List<double> zs,
    List<int> tris,
    int pinnedCount, {
    required int iterations,
  }) {
    final neighbors = List<Set<int>>.generate(zs.length, (_) => <int>{});
    for (var t = 0; t < tris.length; t += 3) {
      final a = tris[t], b = tris[t + 1], c = tris[t + 2];
      neighbors[a]..add(b)..add(c);
      neighbors[b]..add(a)..add(c);
      neighbors[c]..add(a)..add(b);
    }
    const lambda = 0.5;
    for (var it = 0; it < iterations; it++) {
      final next = List<double>.of(zs);
      for (var i = pinnedCount; i < zs.length; i++) {
        final ns = neighbors[i];
        if (ns.isEmpty) continue;
        var sum = 0.0;
        for (final j in ns) {
          sum += zs[j];
        }
        next[i] = zs[i] + lambda * (sum / ns.length - zs[i]);
      }
      for (var i = pinnedCount; i < zs.length; i++) {
        zs[i] = next[i];
      }
    }
  }

  static List<int> _boundaryEdges(List<int> tris) {
    final counts = <int, int>{};
    final directed = <int, List<int>>{};
    var maxIndex = 0;
    for (final i in tris) {
      if (i > maxIndex) maxIndex = i;
    }
    final stride = maxIndex + 1;
    for (var t = 0; t < tris.length; t += 3) {
      for (var e = 0; e < 3; e++) {
        final a = tris[t + e];
        final b = tris[t + (e + 1) % 3];
        final key = a < b ? a * stride + b : b * stride + a;
        counts.update(key, (c) => c + 1, ifAbsent: () => 1);
        directed[key] = <int>[a, b];
      }
    }
    final result = <int>[];
    counts.forEach((key, count) {
      if (count == 1) result.addAll(directed[key]!);
    });
    return result;
  }

  /// Intervalo "redondo" (1, 2, 5 × 10ⁿ m) para unas [targetLevels] curvas.
  static double niceContourStep(double range, {int targetLevels = 6}) {
    if (range <= 0 || !range.isFinite) return 0;
    final raw = range / targetLevels;
    final magnitude = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    for (final m in const <double>[1, 2, 5, 10]) {
      if (m * magnitude >= raw) return m * magnitude;
    }
    return 10 * magnitude;
  }

  /// Curvas de nivel cada [step] metros de altitud real.
  List<ContourSegment> contours(double step) {
    final segments = <ContourSegment>[];
    if (step <= 0 || altitudeRange <= 0) return segments;
    final firstLevel = ((baseAltitude + minZ) / step).ceil();
    final lastLevel = ((baseAltitude + maxZ) / step).floor();
    if (lastLevel - firstLevel > 200) return segments;
    for (var k = firstLevel; k <= lastLevel; k++) {
      final z = k * step - baseAltitude;
      final isIndex = k % 5 == 0;
      for (var t = 0; t < triangles.length; t += 3) {
        final pts = <double>[];
        for (var e = 0; e < 3; e++) {
          final a = triangles[t + e];
          final b = triangles[t + (e + 1) % 3];
          final za = zs[a] - z;
          final zb = zs[b] - z;
          if ((za >= 0 && zb < 0) || (za < 0 && zb >= 0)) {
            final f = za / (za - zb);
            pts
              ..add(xs[a] + (xs[b] - xs[a]) * f)
              ..add(ys[a] + (ys[b] - ys[a]) * f);
          }
        }
        if (pts.length >= 4) {
          segments.add(
            ContourSegment(pts[0], pts[1], pts[2], pts[3], z, t ~/ 3, isIndex),
          );
        }
      }
    }
    return segments;
  }
}
