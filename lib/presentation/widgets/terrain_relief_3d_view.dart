import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/geo_point.dart';
import '../../domain/usecases/geo/geo_projector.dart';
import '../../domain/usecases/geo/terrain_surface.dart';
import 'relief_colors.dart';

/// Vista 3D del relieve construida localmente a partir de la superficie TIN.
///
/// No depende de red ni de DEM: se calcula desde los puntos capturados y se
/// dibuja con un [CustomPainter] propio.
class TerrainRelief3DView extends StatefulWidget {
  final TerrainSurface surface;
  final double verticalExaggeration;
  final bool showWireframe;
  final bool showContours;

  const TerrainRelief3DView({
    super.key,
    required this.surface,
    this.verticalExaggeration = 2.0,
    this.showWireframe = false,
    this.showContours = false,
  });

  @override
  State<TerrainRelief3DView> createState() => _TerrainRelief3DState();
}

class _TerrainRelief3DState extends State<TerrainRelief3DView> {
  double _azimuth = 0.6;
  double _elevation = 0.8;
  double _scale = 1.0;
  double _offsetX = 0.0;
  double _offsetY = 0.0;
  // Iluminación direccional (luz solar).
  double _lightAzimuth = 0.8;
  double _lightElevation = 0.9;

  static const double _viewDistance = 400.0;
  static const double _focalLength = 600.0;

  void _resetCamera() {
    setState(() {
      _azimuth = 0.6;
      _elevation = 0.8;
      _scale = 1.0;
      _offsetX = 0.0;
      _offsetY = 0.0;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _azimuth += details.delta.dx * 0.005;
      _elevation = (_elevation - details.delta.dy * 0.005).clamp(-1.2, 1.2).toDouble();
    });
  }

  void _onPanEnd(DragEndDetails details) {}

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = details.scale.clamp(0.4, 4.0);
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {}

  void _onManualDragUpdate(DragUpdateDetails details) {
    setState(() {
      _offsetX += details.delta.dx;
      _offsetY += details.delta.dy;
    });
  }

  Drag? _startManualDrag(Offset position) {
    return _ManualDrag(_onManualDragUpdate);
  }

  double _altitudeRange(TerrainSurface surface) {
    if (surface.vertices.isEmpty) return 0;
    var min = surface.vertices.first.altitude;
    var max = surface.vertices.first.altitude;
    for (final p in surface.vertices) {
      min = math.min(min, p.altitude);
      max = math.max(max, p.altitude);
    }
    return max - min;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = widget.surface;
    final available = surface.isAvailable;
    return SizedBox.expand(
      child: Stack(
        children: [
          if (available)
            RawGestureDetector(
              gestures: {
                PanGestureRecognizer: GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
                  () => PanGestureRecognizer(),
                  (PanGestureRecognizer instance) {
                    instance.onUpdate = _onPanUpdate;
                    instance.onEnd = _onPanEnd;
                  },
                ),
                ScaleGestureRecognizer: GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
                  () => ScaleGestureRecognizer(),
                  (ScaleGestureRecognizer instance) {
                    instance.onUpdate = _onScaleUpdate;
                    instance.onEnd = _onScaleEnd;
                  },
                ),
                ImmediateMultiDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<ImmediateMultiDragGestureRecognizer>(
                  () => ImmediateMultiDragGestureRecognizer(),
                  (ImmediateMultiDragGestureRecognizer instance) {
                    instance.onStart = _startManualDrag;
                  },
                ),
              },
              child: CustomPaint(
                painter: _TerrainRelief3DPainter(
                  surface: surface,
                  verticalExaggeration: widget.verticalExaggeration,
                  azimuth: _azimuth,
                  elevation: _elevation,
                  scale: _scale,
                  offsetX: _offsetX,
                  offsetY: _offsetY,
                  focalLength: _focalLength,
                  viewDistance: _viewDistance,
                  showWireframe: widget.showWireframe,
                  showContours: widget.showContours,
                  lightAzimuth: _lightAzimuth,
                  lightElevation: _lightElevation,
                  lowColor: theme.colorScheme.primary,
                  middleColor: theme.colorScheme.tertiary,
                  highColor: theme.colorScheme.secondary,
                  labelColor: theme.colorScheme.onSurface,
                  gridColor: theme.colorScheme.outlineVariant,
                ),
              ),
            ),
          if (!available)
            Positioned.fill(
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
            ),
          if (available)
            Positioned(
              top: 8,
              left: 8,
              right: 72,
              child: Text(
                'Representación aproximada: la altitud del GPS tiene menor precisión que la horizontal',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ),
          if (available)
            Positioned(
              top: 40,
              left: 8,
              child: Text(
                'Exageración vertical: ${widget.verticalExaggeration}',
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ),
          if (available && _altitudeRange(surface) == 0)
            Positioned(
              top: 58,
              left: 8,
              right: 72,
              child: Text(
                'Sin variación de altitud: superficie plana. '
                'Capture puntos en diferentes elevaciones.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: Colors.orange),
              ),
            ),
          Positioned(
            top: 8,
            right: 8,
            child: FloatingActionButton.small(
              onPressed: _resetCamera,
              tooltip: 'Restablecer vista 3D',
              child: const Icon(Icons.refresh),
            ),
          ),
        ],
      ),
    );
  }
}

class _VertexProjection {
  final Offset screen;
  final double depth;
  final double nx, ny, nz; // normal del vértice (para Gouraud)

  const _VertexProjection(this.screen, this.depth, this.nx, this.ny, this.nz);
}

class _ManualDrag implements Drag {
  _ManualDrag(this.onUpdate);

  final void Function(DragUpdateDetails details) onUpdate;

  @override
  void update(DragUpdateDetails details) => onUpdate(details);

  @override
  void end(DragEndDetails details) {}

  @override
  void cancel() {}
}

class _TerrainRelief3DPainter extends CustomPainter {
  final TerrainSurface surface;
  final double verticalExaggeration;
  final double azimuth;
  final double elevation;
  final double scale;
  final double offsetX;
  final double offsetY;
  final double focalLength;
  final double viewDistance;
  final bool showWireframe;
  final bool showContours;
  final double lightAzimuth;
  final double lightElevation;
  final Color lowColor;
  final Color middleColor;
  final Color highColor;
  final Color labelColor;
  final Color gridColor;

  _TerrainRelief3DPainter({
    required this.surface,
    required this.verticalExaggeration,
    required this.azimuth,
    required this.elevation,
    required this.scale,
    required this.offsetX,
    required this.offsetY,
    required this.focalLength,
    required this.viewDistance,
    required this.showWireframe,
    required this.showContours,
    required this.lightAzimuth,
    required this.lightElevation,
    required this.lowColor,
    required this.middleColor,
    required this.highColor,
    required this.labelColor,
    required this.gridColor,
  });

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

  /// Proyecta un punto 3D a pantalla con perspectiva.
  _VertexProjection _project(GeoPoint point, GeoProjector projector, double minAltitude, Size size) {
    final projected = projector.project(point);
    final x = projected.x;
    final z = projected.y;
    final height = (point.altitude - minAltitude) * verticalExaggeration;

    final cosA = math.cos(azimuth);
    final sinA = math.sin(azimuth);
    final cosE = math.cos(elevation);
    final sinE = math.sin(elevation);

    final right = x * cosA - z * sinA;
    final up = (x * sinA + z * cosA) * sinE + height * cosE;
    final depth = x * sinA * cosE + z * cosA * cosE - height * sinE;

    final distance = viewDistance - depth;
    if (distance <= 0) {
      return _VertexProjection(Offset(size.width / 2, size.height / 2), double.infinity, 0, 0, 1);
    }
    final factor = focalLength / distance;
    return _VertexProjection(
      Offset(
        size.width / 2 + right * factor * scale + offsetX,
        size.height / 2 - up * factor * scale + offsetY,
      ),
      distance,
      cosE, // nx placeholder
      sinE, // ny placeholder
      1.0,  // nz placeholder
    );
  }

  /// Calcula la normal de un triángulo en espacio 3D (antes de rotación).
  /// Retorna (nx, ny, nz) normalizados.
  (double, double, double) _triangleNormal(List<GeoPoint> tri, GeoProjector projector, double minAltitude) {
    final p0 = projector.project(tri[0]);
    final p1 = projector.project(tri[1]);
    final p2 = projector.project(tri[2]);
    final h0 = (tri[0].altitude - minAltitude) * verticalExaggeration;
    final h1 = (tri[1].altitude - minAltitude) * verticalExaggeration;
    final h2 = (tri[2].altitude - minAltitude) * verticalExaggeration;

    // Vectores en espacio 3D: (x, height, z)
    final v1x = p1.x - p0.x;
    final v1y = h1 - h0;
    final v1z = p1.y - p0.y;
    final v2x = p2.x - p0.x;
    final v2y = h2 - h0;
    final v2z = p2.y - p0.y;

    // Cross product v1 × v2
    final nx = v1y * v2z - v1z * v2y;
    final ny = v1z * v2x - v1x * v2z;
    final nz = v1x * v2y - v1y * v2x;

    final len = math.sqrt(nx * nx + ny * ny + nz * nz);
    if (len < 1e-12) return (0.0, 0.0, 1.0);
    return (nx / len, ny / len, nz / len);
  }

  /// Calcula la iluminación Lambert para un triángulo.
  double _lambert((double, double, double) normal) {
    final (nx, ny, nz) = normal;
    // Rotar la normal por azimut y elevación para obtener la normal en espacio de vista.
    final cosA = math.cos(azimuth);
    final sinA = math.sin(azimuth);
    final cosE = math.cos(elevation);
    final sinE = math.sin(elevation);

    // Rotar normal por azimut (alrededor de Y/altura).
    final nx1 = nx * cosA + nz * sinA;
    final nz1 = -nx * sinA + nz * cosA;
    final ny1 = ny;

    // Rotar por elevación.
    final nx2 = nx1;
    final ny2 = ny1 * cosE - nz1 * sinE;
    final nz2 = ny1 * sinE + nz1 * cosE;

    // Dirección de la luz (en espacio de vista, rotada por lightAzimuth/lightElevation).
    final lcosA = math.cos(lightAzimuth);
    final lsinA = math.sin(lightAzimuth);
    final lcosE = math.cos(lightElevation);
    final lsinE = math.sin(lightElevation);
    final lx = lsinA * lcosE;
    final ly = lsinE;
    final lz = lcosA * lcosE;

    // Dot product normal · light.
    final dot = nx2 * lx + ny2 * ly + nz2 * lz;
    // Ambient + diffuse.
    return (0.25 + 0.75 * dot.clamp(0.0, 1.0)).clamp(0.15, 1.0);
  }

  double _triangleDepth(List<GeoPoint> triangle, GeoProjector projector, double minAltitude) {
    var depth = 0.0;
    for (final point in triangle) {
      depth += _project(point, projector, minAltitude, Size.zero).depth;
    }
    return depth / triangle.length;
  }

  Color _colorFor(List<GeoPoint> triangle, double minAltitude, double lighting) {
    var min = triangle[0].altitude;
    var max = triangle[0].altitude;
    for (final point in triangle) {
      min = math.min(min, point.altitude);
      max = math.max(max, point.altitude);
    }
    final range = max - min;
    if (range <= 0) {
      return lowColor.withValues(alpha: 0.9);
    }
    var height = 0.0;
    for (final point in triangle) {
      height += point.altitude - minAltitude;
    }
    final normalized = (height / triangle.length / range).clamp(0.0, 1.0).toDouble();
    final base = altitudeColor(
      normalized,
      low: lowColor,
      middle: middleColor,
      high: highColor,
    );
    // Aplicar iluminación Lambert.
    final r = (base.r * 255 * lighting).round().clamp(0, 255);
    final g = (base.g * 255 * lighting).round().clamp(0, 255);
    final b = (base.b * 255 * lighting).round().clamp(0, 255);
    return Color.fromARGB((base.a * 255).round(), r, g, b);
  }

  void _paintLabel(Canvas canvas, String text, Offset center, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          shadows: const [Shadow(color: Colors.black54, blurRadius: 2)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  /// Dibuja curvas de nivel (isolíneas) sobre la malla.
  void _paintContours(Canvas canvas, Size size, List<List<GeoPoint>> triangles,
      GeoProjector projector, double minAltitude, double maxAltitude) {
    if (maxAltitude <= minAltitude) return;
    final range = maxAltitude - minAltitude;
    final levels = 5;
    final step = range / (levels + 1);

    for (var i = 1; i <= levels; i++) {
      final level = minAltitude + step * i;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      for (final tri in triangles) {
        // Encontrar intersecciones del nivel con los bordes del triángulo.
        final pts = <Offset>[];
        for (var e = 0; e < 3; e++) {
          final a = tri[e];
          final b = tri[(e + 1) % 3];
          final ha = a.altitude - level;
          final hb = b.altitude - level;
          if ((ha >= 0 && hb < 0) || (ha < 0 && hb >= 0)) {
            final t = ha / (ha - hb);
            final projA = _project(a, projector, minAltitude, size);
            final projB = _project(b, projector, minAltitude, size);
            final ix = projA.screen.dx + (projB.screen.dx - projA.screen.dx) * t;
            final iy = projA.screen.dy + (projB.screen.dy - projA.screen.dy) * t;
            pts.add(Offset(ix, iy));
          }
        }
        if (pts.length >= 2) {
          canvas.drawLine(pts[0], pts[1], paint);
        }
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final triangles = surface.triangles;
    if (triangles.isEmpty) return;

    var minAltitude = triangles.first.first.altitude;
    var maxAltitude = triangles.first.first.altitude;
    for (final triangle in triangles) {
      for (final point in triangle) {
        minAltitude = math.min(minAltitude, point.altitude);
        maxAltitude = math.max(maxAltitude, point.altitude);
      }
    }

    final projector = GeoProjector(_centroid(surface.vertices));

    // Ordenar triángulos por profundidad (de lejos a cerca).
    final sorted = [...triangles]..sort(
        (a, b) => _triangleDepth(a, projector, minAltitude)
            .compareTo(_triangleDepth(b, projector, minAltitude)),
      );

    for (final triangle in sorted) {
      final normal = _triangleNormal(triangle, projector, minAltitude);
      final lighting = _lambert(normal);

      final projected = [
        for (final point in triangle) _project(point, projector, minAltitude, size),
      ];
      final v0 = projected[0].screen;
      final v1 = projected[1].screen;
      final v2 = projected[2].screen;

      final path = Path()
        ..moveTo(v0.dx, v0.dy)
        ..lineTo(v1.dx, v1.dy)
        ..lineTo(v2.dx, v2.dy)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = _colorFor(triangle, minAltitude, lighting)
          ..style = PaintingStyle.fill,
      );

      if (showWireframe) {
        canvas.drawPath(
          path,
          Paint()
            ..color = gridColor.withValues(alpha: 0.6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8,
        );
      }

      _paintLabel(canvas, '${triangle[0].seq + 1}', projected[0].screen, labelColor);
      _paintLabel(canvas, '${triangle[1].seq + 1}', projected[1].screen, labelColor);
      _paintLabel(canvas, '${triangle[2].seq + 1}', projected[2].screen, labelColor);
    }

    // Curvas de nivel.
    if (showContours) {
      _paintContours(canvas, size, sorted, projector, minAltitude, maxAltitude);
    }
  }

  @override
  bool shouldRepaint(covariant _TerrainRelief3DPainter oldDelegate) {
    return oldDelegate.surface != surface ||
        oldDelegate.verticalExaggeration != verticalExaggeration ||
        oldDelegate.azimuth != azimuth ||
        oldDelegate.elevation != elevation ||
        oldDelegate.scale != scale ||
        oldDelegate.offsetX != offsetX ||
        oldDelegate.offsetY != offsetY ||
        oldDelegate.showWireframe != showWireframe ||
        oldDelegate.showContours != showContours ||
        oldDelegate.lightAzimuth != lightAzimuth ||
        oldDelegate.lightElevation != lightElevation ||
        oldDelegate.lowColor != lowColor ||
        oldDelegate.middleColor != middleColor ||
        oldDelegate.highColor != highColor ||
        oldDelegate.labelColor != labelColor;
  }
}
