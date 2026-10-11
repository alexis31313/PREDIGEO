import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/geo_point.dart';
import '../../domain/usecases/geo/geo_projector.dart';
import '../../domain/usecases/geo/point2d.dart';
import 'relief_colors.dart';

/// Vista cenital (plano de planta) del polígono o trayecto medido.
///
/// Es una visualización totalmente local, sin red ni mapas: proyecta los
/// puntos GNSS a un plano en metros usando [GeoProjector] sobre el centroide
/// de la medición y los dibuja a escala.
///
/// Características:
/// - El norte queda arriba.
/// - Escalado automático con margen (padding) para encajar en el espacio
///   disponible, conservando las proporciones.
/// - Vértices coloreados según su altitud (azul = bajo, verde = medio,
///   marrón = alto) y numerados en orden de captura.
/// - Leyenda con el rango de altitudes del recorrido.
class TerrainReliefView extends StatelessWidget {
  /// Puntos GNSS del recorrido, en orden de captura.
  final List<GeoPoint> points;

  /// Si es `true` (o hay 3 o más puntos), se cierra el polígono para rellenarlo.
  final bool? closePolygon;

  /// Precisión horizontal máxima, en metros, para considerar un punto válido.
  final double maxAccuracy;

  const TerrainReliefView({
    super.key,
    required this.points,
    this.closePolygon,
    this.maxAccuracy = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox.expand(
      child: CustomPaint(
        painter: _TerrainReliefPainter(
          points: points,
          closePolygon: closePolygon ?? points.length >= 3,
          maxAccuracy: maxAccuracy,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          outlineColor: theme.colorScheme.onSurfaceVariant,
          labelColor: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _TerrainReliefPainter extends CustomPainter {
  final List<GeoPoint> points;
  final bool closePolygon;
  final double maxAccuracy;
  final Color backgroundColor;
  final Color outlineColor;
  final Color labelColor;

  _TerrainReliefPainter({
    required this.points,
    required this.closePolygon,
    required this.maxAccuracy,
    required this.backgroundColor,
    required this.outlineColor,
    required this.labelColor,
  });

  static const double _padding = 36.0;

  @override
  void paint(Canvas canvas, Size size) {
    final valid = points.where((p) => p.accuracy <= maxAccuracy).toList();

    if (valid.isEmpty ||
        size.width <= 2 * _padding ||
        size.height <= 2 * _padding) {
      _paintEmptyMessage(canvas, size);
      return;
    }

    var minAltitude = valid.first.altitude;
    var maxAltitude = valid.first.altitude;
    var latSum = 0.0;
    var lonSum = 0.0;
    for (final point in valid) {
      minAltitude = math.min(minAltitude, point.altitude);
      maxAltitude = math.max(maxAltitude, point.altitude);
      latSum += point.latitude;
      lonSum += point.longitude;
    }

    final centroid = GeoPoint(
      seq: 0,
      latitude: latSum / valid.length,
      longitude: lonSum / valid.length,
      altitude: 0,
      accuracy: 0,
      timestamp: valid.first.timestamp,
    );
    final projected = GeoProjector(centroid).projectList(valid);

    var minX = projected.first.x;
    var maxX = projected.first.x;
    var minY = projected.first.y;
    var maxY = projected.first.y;
    for (final point in projected) {
      minX = math.min(minX, point.x);
      maxX = math.max(maxX, point.x);
      minY = math.min(minY, point.y);
      maxY = math.max(maxY, point.y);
    }

    var dataWidth = maxX - minX;
    var dataHeight = maxY - minY;
    if (dataWidth <= 0) dataWidth = 1.0;
    if (dataHeight <= 0) dataHeight = 1.0;

    final availableWidth = size.width - 2 * _padding;
    final availableHeight = size.height - 2 * _padding;
    final scale = math.min(
      availableWidth / dataWidth,
      availableHeight / dataHeight,
    );

    final drawingWidth = dataWidth * scale;
    final drawingHeight = dataHeight * scale;
    final offsetX = (size.width - drawingWidth) / 2;
    final offsetY = (size.height - drawingHeight) / 2;

    Offset toScreen(Point2D point) {
      final x = offsetX + (point.x - minX) * scale;
      // El eje Y del plano apunta al norte; en pantalla el norte es "arriba".
      final y = offsetY + drawingHeight - (point.y - minY) * scale;
      return Offset(x, y);
    }

    final screenPoints = projected.map(toScreen).toList(growable: false);
    final altitudeRange = maxAltitude - minAltitude;

    // Relleno del polígono.
    if (closePolygon && screenPoints.length >= 3) {
      final polygon = Path()
        ..moveTo(screenPoints.first.dx, screenPoints.first.dy);
      for (var i = 1; i < screenPoints.length; i++) {
        polygon.lineTo(screenPoints[i].dx, screenPoints[i].dy);
      }
      polygon.close();
      canvas.drawPath(
        polygon,
        Paint()
          ..color = backgroundColor.withValues(alpha: 0.6)
          ..style = PaintingStyle.fill,
      );

      // Conexión del polígono.
      canvas.drawPath(
        Path.from(polygon),
        Paint()
          ..color = outlineColor.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Trayecto (línea abierta) entre puntos consecutivos.
    if (screenPoints.length >= 2) {
      final linePaint = Paint()
        ..color = outlineColor.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeJoin = StrokeJoin.round;
      for (var i = 0; i < screenPoints.length - 1; i++) {
        canvas.drawLine(screenPoints[i], screenPoints[i + 1], linePaint);
      }
      if (!closePolygon && screenPoints.length >= 2) {
        // Marcador de inicio y fin para trayectos.
        canvas.drawCircle(
          screenPoints.first,
          5,
          Paint()..color = reliefLowColor,
        );
        canvas.drawCircle(
          screenPoints.last,
          5,
          Paint()..color = reliefHighColor,
        );
      }
    }

    // Vértices coloreados por altitud y numerados.
    for (var i = 0; i < screenPoints.length; i++) {
      final t = altitudeRange <= 0
          ? 0.5
          : (valid[i].altitude - minAltitude) / altitudeRange;
      final color = altitudeColor(t);
      final center = screenPoints[i];
      canvas.drawCircle(center, 7, Paint()..color = Colors.white);
      canvas.drawCircle(center, 5.5, Paint()..color = color);
      _paintVertexLabel(canvas, '${i + 1}', center);
    }

    _paintLegend(canvas, size, minAltitude, maxAltitude);
  }

  void _paintVertexLabel(Canvas canvas, String text, Offset center) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  void _paintLegend(
    Canvas canvas,
    Size size,
    double minAltitude,
    double maxAltitude,
  ) {
    const barWidth = 12.0;
    const barHeight = 64.0;
    final left = size.width - _padding - barWidth;
    const top = _padding;

    final rect = Rect.fromLTWH(left, top, barWidth, barHeight);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [reliefLowColor, reliefMidColor, reliefHighColor],
        ).createShader(rect),
    );

    final delta = maxAltitude - minAltitude;
    _paintLegendText(
      canvas,
      '${maxAltitude.toStringAsFixed(0)} m',
      Offset(left - 6, top - 4),
      align: TextAlign.right,
    );
    _paintLegendText(
      canvas,
      '${minAltitude.toStringAsFixed(0)} m',
      Offset(left - 6, top + barHeight - 6),
      align: TextAlign.right,
    );
    _paintLegendText(
      canvas,
      'Desnivel ${delta.toStringAsFixed(0)} m',
      Offset(size.width - _padding - 96, top + barHeight + 6),
      maxWidth: 96,
      align: TextAlign.right,
    );
  }

  void _paintLegendText(
    Canvas canvas,
    String text,
    Offset offset, {
    double maxWidth = 80,
    TextAlign align = TextAlign.left,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: labelColor, fontSize: 10),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, offset);
  }

  void _paintEmptyMessage(Canvas canvas, Size size) {
    final painter = TextPainter(
      text: TextSpan(
        text: 'Sin puntos para mostrar',
        style: TextStyle(color: outlineColor, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    painter.paint(
      canvas,
      Offset(
        (size.width - painter.width) / 2,
        (size.height - painter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _TerrainReliefPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.closePolygon != closePolygon ||
        oldDelegate.maxAccuracy != maxAccuracy;
  }
}
