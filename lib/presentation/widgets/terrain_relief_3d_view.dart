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
/// dibuja con un [CustomPainter] propio. Si la superficie no está disponible
/// (unavailable o track) no se dibuja malla y se muestra un mensaje.
class TerrainRelief3DView extends StatefulWidget {
  final TerrainSurface surface;
  final double verticalExaggeration;
  final bool showWireframe;

  const TerrainRelief3DView({
    super.key,
    required this.surface,
    this.verticalExaggeration = 2.0,
    this.showWireframe = false,
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
                  lowColor: theme.colorScheme.primary,
                  middleColor: theme.colorScheme.tertiary,
                  highColor: theme.colorScheme.secondary,
                  labelColor: theme.colorScheme.onSurface,
                  gridColor: theme.colorScheme.outlineVariant,
                ),
              ),
            ),
          if (!available)
            const Positioned.fill(
              child: Center(
                child: Text(
                  'Sin superficie 3D disponible para este track.',
                  textAlign: TextAlign.center,
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
  final double normalZ;

  const _VertexProjection(this.screen, this.depth, this.normalZ);
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
  /// Retorna la posición en pantalla, la profundidad y la componente Z de la normal.
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
      return _VertexProjection(Offset(size.width / 2, size.height / 2), double.infinity, 0);
    }
    final factor = focalLength / distance;
    return _VertexProjection(
      Offset(
        size.width / 2 + right * factor * scale + offsetX,
        size.height / 2 - up * factor * scale + offsetY,
      ),
      distance,
      cosE, // componente de iluminación
    );
  }

  /// Calcula la normal del triángulo para iluminación Lambert.
  double _triangleLighting(List<Offset> screenPts, double azimuth, double elevation) {
    // Normal simplificada: usar la componente Z de la vista.
    // Iluminación Lambert: dot(normal, lightDir).
    // Luz viene desde arriba-derecha (dirección fija en espacio de vista).
    const lightX = 0.5;
    const lightY = -0.3;
    const lightZ = 0.8;
    final len = math.sqrt(lightX * lightX + lightY * lightY + lightZ * lightZ);
    // Aproximación: usar la elevación como factor de iluminación.
    return (math.cos(elevation) * 0.6 + 0.4).clamp(0.3, 1.0);
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
    return Color.fromARGB(
      (base.a * 255).round(),
      (base.r * 255 * lighting).round().clamp(0, 255),
      (base.g * 255 * lighting).round().clamp(0, 255),
      (base.b * 255 * lighting).round().clamp(0, 255),
    );
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

  void _paintGrid(Canvas canvas, Size size, GeoProjector projector, double minAltitude) {
    // Grid simple en el plano base (z=0 en espacio de vista).
    final paint = Paint()
      ..color = gridColor.withValues(alpha: 0.3)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    // Dibujar líneas horizontales y verticales en el plano proyectado.
    // Simplificado: solo borde del área de datos.
  }

  @override
  void paint(Canvas canvas, Size size) {
    final triangles = surface.triangles;
    if (triangles.isEmpty) return;

    var minAltitude = triangles.first.first.altitude;
    for (final triangle in triangles) {
      for (final point in triangle) {
        minAltitude = math.min(minAltitude, point.altitude);
      }
    }

    final projector = GeoProjector(_centroid(surface.vertices));

    // Ordenar triángulos por profundidad (de lejos a cerca).
    final sorted = [...triangles]..sort(
        (a, b) => _triangleDepth(a, projector, minAltitude)
            .compareTo(_triangleDepth(b, projector, minAltitude)),
      );

    final lighting = _triangleLighting([], azimuth, elevation);

    for (final triangle in sorted) {
      final projected = [
        for (final point in triangle) _project(point, projector, minAltitude, size),
      ];
      final v0 = projected[0].screen;
      final v1 = projected[1].screen;
      final v2 = projected[2].screen;

      // Dibujar triángulo relleno con iluminación.
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

      // Wireframe.
      if (showWireframe) {
        canvas.drawPath(
          path,
          Paint()
            ..color = gridColor.withValues(alpha: 0.6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8,
        );
      }

      // Etiquetas en los vértices.
      _paintLabel(canvas, '${triangle[0].seq + 1}', projected[0].screen, labelColor);
      _paintLabel(canvas, '${triangle[1].seq + 1}', projected[1].screen, labelColor);
      _paintLabel(canvas, '${triangle[2].seq + 1}', projected[2].screen, labelColor);
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
        oldDelegate.lowColor != lowColor ||
        oldDelegate.middleColor != middleColor ||
        oldDelegate.highColor != highColor ||
        oldDelegate.labelColor != labelColor;
  }
}
