import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../domain/usecases/geo/terrain_mesh.dart';
import '../../domain/usecases/geo/terrain_surface.dart';
import 'relief_colors.dart';
import 'terrain_camera.dart';

/// Texto del aviso de precisión mostrado sobre la vista 3D.
const String terrainAccuracyDisclaimer =
    'Representación aproximada: la altitud del GPS tiene menor precisión que la horizontal';

/// Calcula una exageración vertical automática para que el desnivel ocupe
/// aproximadamente un cuarto de la extensión horizontal del terreno.
double autoVerticalExaggeration(TerrainMesh mesh) {
  final range = mesh.altitudeRange;
  if (range < 0.05) return 1.0;
  final value = 0.25 * mesh.horizontalExtent / range;
  return value.clamp(1.0, 50.0).toDouble();
}

/// Vista 3D del relieve construida localmente a partir de la superficie TIN.
///
/// No depende de red ni de DEM: se calcula desde los puntos capturados y se
/// dibuja con un [CustomPainter] propio usando `Canvas.drawVertices`.
///
/// Gestos: un dedo rota la cámara, dos dedos acercan/alejan y desplazan; la
/// rueda del ratón también acerca/aleja.
class TerrainRelief3DView extends StatefulWidget {
  final TerrainSurface surface;

  /// Exageración vertical. `null` = automática según el terreno.
  final double? verticalExaggeration;
  final bool showWireframe;
  final bool showContours;

  /// Subdivide y suaviza la malla para un relieve más continuo.
  final bool smooth;

  /// Muestra las etiquetas de los puntos medidos.
  final bool showLabels;

  const TerrainRelief3DView({
    super.key,
    required this.surface,
    this.verticalExaggeration,
    this.showWireframe = false,
    this.showContours = false,
    this.smooth = false,
    this.showLabels = true,
  });

  @override
  State<TerrainRelief3DView> createState() => _TerrainRelief3DState();
}

class _TerrainRelief3DState extends State<TerrainRelief3DView> {
  TerrainCamera _camera = TerrainCamera.initial;
  double _zoomAtGestureStart = 1.0;
  int _lastPointerCount = 0;

  TerrainMesh? _mesh;
  _PreparedMesh? _prepared;
  List<ContourSegment> _contours = const <ContourSegment>[];
  double _contourStep = 0;
  final Map<String, TextPainter> _labelCache = <String, TextPainter>{};

  @override
  void initState() {
    super.initState();
    _rebuildMesh();
  }

  @override
  void didUpdateWidget(covariant TerrainRelief3DView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.surface, widget.surface) ||
        oldWidget.smooth != widget.smooth) {
      _rebuildMesh();
    } else if (oldWidget.verticalExaggeration != widget.verticalExaggeration) {
      _rebuildPrepared();
    }
  }

  @override
  void dispose() {
    for (final painter in _labelCache.values) {
      painter.dispose();
    }
    super.dispose();
  }

  void _rebuildMesh() {
    final surface = widget.surface;
    if (!surface.isAvailable) {
      _mesh = null;
      _prepared = null;
      _contours = const <ContourSegment>[];
      return;
    }
    final mesh = TerrainMesh.fromSurface(
      surface,
      subdivisions: widget.smooth ? _smoothSubdivisions(surface) : 1,
    );
    _mesh = mesh;
    _contourStep = TerrainMesh.niceContourStep(mesh.altitudeRange);
    _contours = mesh.contours(_contourStep);
    _rebuildPrepared();
  }

  /// Limita la subdivisión para que la malla no pase de ~6000 triángulos.
  int _smoothSubdivisions(TerrainSurface surface) {
    final count = math.max(1, surface.triangleIndices.length);
    for (final n in const <int>[4, 3, 2]) {
      if (count * n * n <= 6000) return n;
    }
    return 1;
  }

  double get _exaggeration {
    final mesh = _mesh;
    if (mesh == null) return 1.0;
    return widget.verticalExaggeration ?? autoVerticalExaggeration(mesh);
  }

  void _rebuildPrepared() {
    final mesh = _mesh;
    _prepared = mesh == null ? null : _PreparedMesh(mesh, _exaggeration);
  }

  void _resetCamera() {
    setState(() => _camera = TerrainCamera.initial);
  }

  void _onScaleStart(ScaleStartDetails details) {
    _zoomAtGestureStart = _camera.zoom;
    _lastPointerCount = details.pointerCount;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    // Al cambiar el número de dedos, la escala del gesto se reinicia.
    if (details.pointerCount != _lastPointerCount) {
      _lastPointerCount = details.pointerCount;
      _zoomAtGestureStart = _camera.zoom / details.scale;
    }
    setState(() {
      if (details.pointerCount <= 1) {
        final delta = details.focalPointDelta;
        _camera = _camera.copyWith(
          azimuth: _camera.azimuth - delta.dx * 0.009,
          elevation: _camera.elevation + delta.dy * 0.006,
        );
      } else {
        _camera = _camera.copyWith(
          zoom: _zoomAtGestureStart * details.scale,
          pan: _camera.pan + details.focalPointDelta,
        );
      }
    });
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      final factor = event.scrollDelta.dy > 0 ? 0.9 : 1.1;
      setState(() => _camera = _camera.copyWith(zoom: _camera.zoom * factor));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final surface = widget.surface;
    final mesh = _mesh;
    final prepared = _prepared;
    final available = surface.isAvailable && mesh != null && prepared != null;

    if (!available) {
      return SizedBox.expand(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              surface.reason != null
                  ? 'Sin superficie 3D disponible.\n${surface.reason}'
                  : 'Sin superficie 3D disponible para este track.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final overlayStyle = TextStyle(fontSize: 10, color: colors.onSurfaceVariant);
    final exaggeration = _exaggeration;
    final isFlat = mesh.altitudeRange < 0.05;

    return SizedBox.expand(
      child: ClipRect(
        child: Stack(
          children: [
            Positioned.fill(
              child: Listener(
                onPointerSignal: _onPointerSignal,
                child: RawGestureDetector(
                  behavior: HitTestBehavior.opaque,
                  gestures: <Type, GestureRecognizerFactory>{
                    _EagerScaleGestureRecognizer:
                        GestureRecognizerFactoryWithHandlers<
                            _EagerScaleGestureRecognizer>(
                      _EagerScaleGestureRecognizer.new,
                      (instance) {
                        instance
                          ..onStart = _onScaleStart
                          ..onUpdate = _onScaleUpdate;
                      },
                    ),
                  },
                  child: CustomPaint(
                    painter: _TerrainRelief3DPainter(
                      prepared: prepared,
                      camera: _camera,
                      contours: widget.showContours ? _contours : null,
                      showWireframe: widget.showWireframe,
                      showLabels: widget.showLabels,
                      labelCache: _labelCache,
                      gridColor: colors.outlineVariant,
                      labelColor: colors.onSurface,
                      haloColor: colors.surface,
                      contourColor: theme.brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 6,
              left: 8,
              right: 52,
              child: Text(
                terrainAccuracyDisclaimer,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: overlayStyle,
              ),
            ),
            if (isFlat)
              Positioned(
                top: 34,
                left: 8,
                right: 52,
                child: Text(
                  'Sin variación de altitud: superficie plana. '
                  'Capture puntos en diferentes elevaciones.',
                  style: overlayStyle.copyWith(color: Colors.orange.shade800),
                ),
              ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton.filledTonal(
                onPressed: _resetCamera,
                tooltip: 'Restablecer vista 3D',
                iconSize: 18,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.refresh),
              ),
            ),
            Positioned(
              left: 6,
              bottom: 6,
              child: _Legend(
                minAltitude: mesh.baseAltitude + mesh.minZ,
                maxAltitude: mesh.baseAltitude + mesh.maxZ,
                exaggeration: exaggeration,
                isAuto: widget.verticalExaggeration == null,
                contourStep: widget.showContours ? _contourStep : null,
                gridStep: prepared.gridStep,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reconocedor de escala que gana la arena de gestos de inmediato, para que
/// el desplazamiento del contenedor (scroll) no robe los arrastres.
class _EagerScaleGestureRecognizer extends ScaleGestureRecognizer {
  _EagerScaleGestureRecognizer() : super();

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}

class _Legend extends StatelessWidget {
  final double minAltitude;
  final double maxAltitude;
  final double exaggeration;
  final bool isAuto;
  final double? contourStep;
  final double gridStep;

  const _Legend({
    required this.minAltitude,
    required this.maxAltitude,
    required this.exaggeration,
    required this.isAuto,
    required this.contourStep,
    required this.gridStep,
  });

  String _meters(double value) =>
      value >= 10 || value == value.roundToDouble()
          ? '${value.toStringAsFixed(0)} m'
          : '${value.toStringAsFixed(1)} m';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final style = TextStyle(fontSize: 9.5, color: colors.onSurface);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exageración vertical: ${exaggeration.toStringAsFixed(1)}x'
              '${isAuto ? ' (auto)' : ''}',
              style: style,
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${maxAltitude.toStringAsFixed(1)} m', style: style),
                const SizedBox(width: 4),
                Container(
                  width: 56,
                  height: 7,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: const LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: hypsometricStops,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text('${minAltitude.toStringAsFixed(1)} m', style: style),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Cuadrícula: ${_meters(gridStep)}'
              '${contourStep != null && contourStep! > 0 ? ' · Curvas: ${_meters(contourStep!)}' : ''}',
              style: style,
            ),
          ],
        ),
      ),
    );
  }
}

/// Datos de la malla que solo dependen de la exageración vertical (no de la
/// cámara): alturas escaladas, colores por vértice ya iluminados y normales.
class _PreparedMesh {
  final TerrainMesh mesh;
  final double exaggeration;

  /// z escalada por la exageración.
  late final Float64List zScaled;

  /// Color ARGB iluminado de cada vértice.
  late final Int32List vertexColors;

  /// Normal (unitaria) de cada triángulo superior: 3 componentes por triángulo.
  late final Float64List faceNormals;

  /// Base del bloque (z escalada) para las paredes laterales.
  late final double baseZ;

  /// Espaciado de la cuadrícula de referencia (m).
  late final double gridStep;

  /// Radio de la esfera que envuelve la escena.
  late final double radius;

  late final double centerZ;

  // Luz solar fija respecto al terreno: desde el noroeste, 45° de altura
  // (convención de sombreado cartográfico).
  static const double _lx = -0.5;
  static const double _ly = 0.5;
  static const double _lz = 0.70710678;

  _PreparedMesh(this.mesh, this.exaggeration) {
    final n = mesh.vertexCount;
    zScaled = Float64List(n);
    for (var i = 0; i < n; i++) {
      zScaled[i] = mesh.zs[i] * exaggeration;
    }

    final tris = mesh.triangles;
    final triCount = mesh.triangleCount;
    faceNormals = Float64List(triCount * 3);
    final vn = Float64List(n * 3);
    for (var t = 0; t < triCount; t++) {
      final a = tris[t * 3], b = tris[t * 3 + 1], c = tris[t * 3 + 2];
      final ux = mesh.xs[b] - mesh.xs[a];
      final uy = mesh.ys[b] - mesh.ys[a];
      final uz = zScaled[b] - zScaled[a];
      final vx = mesh.xs[c] - mesh.xs[a];
      final vy = mesh.ys[c] - mesh.ys[a];
      final vz = zScaled[c] - zScaled[a];
      var nx = uy * vz - uz * vy;
      var ny = uz * vx - ux * vz;
      var nz = ux * vy - uy * vx;
      final len = math.sqrt(nx * nx + ny * ny + nz * nz);
      if (len < 1e-12) {
        nx = 0;
        ny = 0;
        nz = 1;
      } else {
        nx /= len;
        ny /= len;
        nz /= len;
      }
      faceNormals[t * 3] = nx;
      faceNormals[t * 3 + 1] = ny;
      faceNormals[t * 3 + 2] = nz;
      for (final v in <int>[a, b, c]) {
        vn[v * 3] += nx;
        vn[v * 3 + 1] += ny;
        vn[v * 3 + 2] += nz;
      }
    }

    final range = mesh.altitudeRange;
    vertexColors = Int32List(n);
    for (var i = 0; i < n; i++) {
      final nx = vn[i * 3], ny = vn[i * 3 + 1], nz = vn[i * 3 + 2];
      final len = math.sqrt(nx * nx + ny * ny + nz * nz);
      final dot = len < 1e-12
          ? _lz
          : (nx * _lx + ny * _ly + nz * _lz) / len;
      final shade = 0.38 + 0.62 * dot.clamp(0.0, 1.0) / _lz * 0.82;
      final t = range > 0 ? (mesh.zs[i] - mesh.minZ) / range : 0.5;
      vertexColors[i] = _shadeColor(hypsometricColor(t), shade);
    }

    final relief = (mesh.maxZ - mesh.minZ) * exaggeration;
    final extent = mesh.horizontalExtent;
    baseZ = mesh.minZ * exaggeration - math.max(relief * 0.18, extent * 0.04);
    final topZ = mesh.maxZ * exaggeration;
    centerZ = (baseZ + topZ) / 2;
    final dz = topZ - baseZ;
    radius = 0.5 *
        math.sqrt(mesh.spanX * mesh.spanX + mesh.spanY * mesh.spanY + dz * dz);
    gridStep = TerrainMesh.niceContourStep(extent * 1.2, targetLevels: 6);
  }

  static int _shadeColor(Color color, double shade) {
    final s = shade.clamp(0.0, 1.15);
    final r = (color.r * 255 * s).round().clamp(0, 255);
    final g = (color.g * 255 * s).round().clamp(0, 255);
    final b = (color.b * 255 * s).round().clamp(0, 255);
    return (0xFF << 24) | (r << 16) | (g << 8) | b;
  }

  /// Color de una pared lateral con normal horizontal (ox, oy).
  static int wallColor(double ox, double oy, {required bool bottom}) {
    final dot = (ox * _lx + oy * _ly).clamp(0.0, 1.0);
    final shade = (0.45 + 0.5 * dot) * (bottom ? 0.62 : 1.0);
    return _shadeColor(const Color(0xFF7A5536), shade);
  }
}

class _TerrainRelief3DPainter extends CustomPainter {
  final _PreparedMesh prepared;
  final TerrainCamera camera;
  final List<ContourSegment>? contours;
  final bool showWireframe;
  final bool showLabels;
  final Map<String, TextPainter> labelCache;
  final Color gridColor;
  final Color labelColor;
  final Color haloColor;
  final Color contourColor;

  _TerrainRelief3DPainter({
    required this.prepared,
    required this.camera,
    required this.contours,
    required this.showWireframe,
    required this.showLabels,
    required this.labelCache,
    required this.gridColor,
    required this.labelColor,
    required this.haloColor,
    required this.contourColor,
  });

  TerrainMesh get mesh => prepared.mesh;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || mesh.triangleCount == 0) return;

    final projection = TerrainProjection(
      camera: camera,
      size: size,
      cx: mesh.centerX,
      cy: mesh.centerY,
      cz: prepared.centerZ,
      radius: prepared.radius,
    );
    final (vx, vy, vz) = camera.towardViewer;

    // 1. Proyección de todos los vértices superiores.
    final n = mesh.vertexCount;
    final sx = Float64List(n);
    final sy = Float64List(n);
    final depth = Float64List(n);
    for (var i = 0; i < n; i++) {
      final (px, py, d) =
          projection.project(mesh.xs[i], mesh.ys[i], prepared.zScaled[i]);
      sx[i] = px;
      sy[i] = py;
      depth[i] = d;
    }

    _paintGrid(canvas, projection);

    // 2. Paredes laterales visibles (bloque de terreno).
    final edges = mesh.boundaryEdges;
    final wallA = <int>[];
    final wallB = <int>[];
    final wallNormals = <double>[];
    for (var e = 0; e < edges.length; e += 2) {
      final a = edges[e], b = edges[e + 1];
      final ex = mesh.xs[b] - mesh.xs[a];
      final ey = mesh.ys[b] - mesh.ys[a];
      final len = math.sqrt(ex * ex + ey * ey);
      if (len < 1e-9) continue;
      final ox = ey / len, oy = -ex / len; // exterior a la derecha
      if (ox * vx + oy * vy <= 0) continue; // de espaldas a la cámara
      wallA.add(a);
      wallB.add(b);
      wallNormals
        ..add(ox)
        ..add(oy);
    }
    final wallCount = wallA.length;
    final bottomX = Float64List(wallCount * 2);
    final bottomY = Float64List(wallCount * 2);
    final bottomD = Float64List(wallCount * 2);
    for (var w = 0; w < wallCount; w++) {
      for (var k = 0; k < 2; k++) {
        final v = k == 0 ? wallA[w] : wallB[w];
        final (px, py, d) =
            projection.project(mesh.xs[v], mesh.ys[v], prepared.baseZ);
        bottomX[w * 2 + k] = px;
        bottomY[w * 2 + k] = py;
        bottomD[w * 2 + k] = d;
      }
    }

    // 3. Orden de pintado: de lejos a cerca (algoritmo del pintor).
    final triCount = mesh.triangleCount;
    final itemCount = triCount + wallCount;
    final itemDepth = Float64List(itemCount);
    final tris = mesh.triangles;
    for (var t = 0; t < triCount; t++) {
      itemDepth[t] = (depth[tris[t * 3]] +
              depth[tris[t * 3 + 1]] +
              depth[tris[t * 3 + 2]]) /
          3;
    }
    for (var w = 0; w < wallCount; w++) {
      itemDepth[triCount + w] = (depth[wallA[w]] +
              depth[wallB[w]] +
              bottomD[w * 2] +
              bottomD[w * 2 + 1]) /
          4;
    }
    final order = List<int>.generate(itemCount, (i) => i)
      ..sort((a, b) => itemDepth[b].compareTo(itemDepth[a]));

    final vertexTotal = (triCount + wallCount * 2) * 3;
    final positions = Float32List(vertexTotal * 2);
    final colorData = Int32List(vertexTotal);
    var p = 0;
    var c = 0;
    void emit(double x, double y, int color) {
      positions[p++] = x;
      positions[p++] = y;
      colorData[c++] = color;
    }

    for (final item in order) {
      if (item < triCount) {
        for (var k = 0; k < 3; k++) {
          final v = tris[item * 3 + k];
          emit(sx[v], sy[v], prepared.vertexColors[v]);
        }
      } else {
        final w = item - triCount;
        final a = wallA[w], b = wallB[w];
        final ox = wallNormals[w * 2], oy = wallNormals[w * 2 + 1];
        final top = _PreparedMesh.wallColor(ox, oy, bottom: false);
        final bottom = _PreparedMesh.wallColor(ox, oy, bottom: true);
        emit(sx[a], sy[a], top);
        emit(sx[b], sy[b], top);
        emit(bottomX[w * 2 + 1], bottomY[w * 2 + 1], bottom);
        emit(sx[a], sy[a], top);
        emit(bottomX[w * 2 + 1], bottomY[w * 2 + 1], bottom);
        emit(bottomX[w * 2], bottomY[w * 2], bottom);
      }
    }

    canvas.drawVertices(
      ui.Vertices.raw(
        ui.VertexMode.triangles,
        positions,
        colors: colorData,
      ),
      BlendMode.dst,
      Paint(),
    );

    bool facesViewer(int t) {
      final fn = prepared.faceNormals;
      return fn[t * 3] * vx + fn[t * 3 + 1] * vy + fn[t * 3 + 2] * vz > 0.02;
    }

    // 4. Malla (wireframe) de las caras visibles.
    if (showWireframe) {
      final path = Path();
      for (var t = 0; t < triCount; t++) {
        if (!facesViewer(t)) continue;
        final a = tris[t * 3], b = tris[t * 3 + 1], cc = tris[t * 3 + 2];
        path
          ..moveTo(sx[a], sy[a])
          ..lineTo(sx[b], sy[b])
          ..lineTo(sx[cc], sy[cc])
          ..close();
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6
          ..color = Colors.white.withValues(alpha: 0.45),
      );
    }

    // 5. Curvas de nivel sobre las caras visibles.
    final segments = contours;
    if (segments != null && segments.isNotEmpty) {
      final normal = Path();
      final index = Path();
      final ex = prepared.exaggeration;
      for (final s in segments) {
        if (!facesViewer(s.triangle)) continue;
        final (ax, ay, _) = projection.project(s.x1, s.y1, s.z * ex);
        final (bx, by, _) = projection.project(s.x2, s.y2, s.z * ex);
        (s.isIndex ? index : normal)
          ..moveTo(ax, ay)
          ..lineTo(bx, by);
      }
      canvas.drawPath(
        normal,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9
          ..color = contourColor.withValues(alpha: 0.45),
      );
      canvas.drawPath(
        index,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = contourColor.withValues(alpha: 0.65),
      );
    }

    // 6. Puntos medidos y sus etiquetas (una sola vez por punto).
    final pointFill = Paint()..style = PaintingStyle.fill;
    final pointStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.black.withValues(alpha: 0.7);
    final labelAll = mesh.dataVertices.length <= 40;
    for (var i = 0; i < mesh.dataVertices.length; i++) {
      final v = mesh.dataVertices[i];
      final interior = mesh.dataInterior[i];
      final center = Offset(sx[v], sy[v]);
      pointFill.color =
          interior ? const Color(0xFFFFC107) : const Color(0xFFFFFFFF);
      canvas.drawCircle(center, 3.2, pointFill);
      canvas.drawCircle(center, 3.2, pointStroke);
      if (showLabels && (labelAll || !interior)) {
        _paintLabel(canvas, mesh.dataLabels[i], center + const Offset(5, -12));
      }
    }

    _paintNorthArrow(canvas, size);
  }

  void _paintGrid(Canvas canvas, TerrainProjection projection) {
    final step = prepared.gridStep;
    if (step <= 0) return;
    final pad = mesh.horizontalExtent * 0.08;
    final x0 = ((mesh.minX - pad) / step).floor() * step;
    final x1 = ((mesh.maxX + pad) / step).ceil() * step;
    final y0 = ((mesh.minY - pad) / step).floor() * step;
    final y1 = ((mesh.maxY + pad) / step).ceil() * step;
    if ((x1 - x0) / step > 60 || (y1 - y0) / step > 60) return;
    final z = prepared.baseZ;
    final path = Path();
    for (var x = x0; x <= x1 + 1e-9; x += step) {
      final (ax, ay, _) = projection.project(x, y0, z);
      final (bx, by, _) = projection.project(x, y1, z);
      path
        ..moveTo(ax, ay)
        ..lineTo(bx, by);
    }
    for (var y = y0; y <= y1 + 1e-9; y += step) {
      final (ax, ay, _) = projection.project(x0, y, z);
      final (bx, by, _) = projection.project(x1, y, z);
      path
        ..moveTo(ax, ay)
        ..lineTo(bx, by);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6
        ..color = gridColor.withValues(alpha: 0.7),
    );
  }

  void _paintLabel(Canvas canvas, String text, Offset topLeft) {
    final key = '$text|${labelColor.toARGB32()}|${haloColor.toARGB32()}';
    final painter = labelCache.putIfAbsent(key, () {
      return TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: labelColor,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            shadows: [
              Shadow(color: haloColor, blurRadius: 2),
              Shadow(color: haloColor, blurRadius: 3),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    });
    painter.paint(canvas, topLeft);
  }

  /// Flecha de norte en la esquina inferior derecha, orientada según la
  /// cámara.
  void _paintNorthArrow(Canvas canvas, Size size) {
    final center = Offset(size.width - 22, size.height - 24);
    final sinA = math.sin(camera.azimuth), cosA = math.cos(camera.azimuth);
    final dirX = -sinA;
    final dirY = -cosA * math.sin(camera.elevation);
    final len = math.sqrt(dirX * dirX + dirY * dirY);
    if (len < 1e-6) return;
    final ux = dirX / len, uy = dirY / len;
    canvas.drawCircle(
      center,
      14,
      Paint()..color = haloColor.withValues(alpha: 0.8),
    );
    final tip = center + Offset(ux, uy) * 10;
    final tail = center - Offset(ux, uy) * 7;
    final side = Offset(-uy, ux) * 4.5;
    final arrow = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tail.dx + side.dx, tail.dy + side.dy)
      ..lineTo(center.dx, center.dy)
      ..lineTo(tail.dx - side.dx, tail.dy - side.dy)
      ..close();
    canvas.drawPath(arrow, Paint()..color = const Color(0xFFD32F2F));
    final label = labelCache.putIfAbsent('__N__|${labelColor.toARGB32()}', () {
      return TextPainter(
        text: TextSpan(
          text: 'N',
          style: TextStyle(
            color: labelColor,
            fontSize: 8,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    });
    final labelPos = center + Offset(ux, uy) * 19;
    label.paint(
      canvas,
      labelPos - Offset(label.width / 2, label.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _TerrainRelief3DPainter old) {
    return !identical(old.prepared, prepared) ||
        old.camera != camera ||
        !identical(old.contours, contours) ||
        old.showWireframe != showWireframe ||
        old.showLabels != showLabels ||
        old.gridColor != gridColor ||
        old.labelColor != labelColor ||
        old.haloColor != haloColor ||
        old.contourColor != contourColor;
  }
}
