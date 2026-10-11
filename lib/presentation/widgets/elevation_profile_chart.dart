import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/geo_point.dart';
import '../../domain/usecases/geo/distance_calculator.dart';

/// Gráfico del perfil de altitud frente a la distancia acumulada.
///
/// Dibuja, mediante un [CustomPainter] y sin ninguna dependencia de red ni de
/// mapas, la evolución de la altitud a lo largo del recorrido. El eje vertical
/// representa la altitud en metros y el horizontal la distancia acumulada.
///
/// Características:
/// - Ejes con etiquetas de altitud y distancia.
/// - Área rellena con un degradado bajo la curva de perfil.
/// - Descarta los puntos de baja precisión ([maxAccuracy]) para no dibujar
///   picos irreales de altitud.
///
/// Es reutilizable tanto en la pantalla de medición como en el historial: solo
/// necesita la lista de puntos.
class ElevationProfileChart extends StatelessWidget {
  /// Puntos GNSS del recorrido, en orden de captura.
  final List<GeoPoint> points;

  /// Precisión horizontal máxima, en metros, para considerar un punto válido.
  final double maxAccuracy;

  const ElevationProfileChart({
    super.key,
    required this.points,
    this.maxAccuracy = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox.expand(
      child: CustomPaint(
        painter: _ElevationProfilePainter(
          points: points,
          maxAccuracy: maxAccuracy,
          axisColor: theme.colorScheme.outlineVariant,
          labelColor: theme.colorScheme.onSurfaceVariant,
          lineColor: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _ElevationProfilePainter extends CustomPainter {
  final List<GeoPoint> points;
  final double maxAccuracy;
  final Color axisColor;
  final Color labelColor;
  final Color lineColor;

  _ElevationProfilePainter({
    required this.points,
    required this.maxAccuracy,
    required this.axisColor,
    required this.labelColor,
    required this.lineColor,
  });

  static const double _leftPadding = 48.0;
  static const double _rightPadding = 12.0;
  static const double _topPadding = 12.0;
  static const double _bottomPadding = 28.0;

  @override
  void paint(Canvas canvas, Size size) {
    final valid = points.where((p) => p.accuracy <= maxAccuracy).toList();

    if (valid.isEmpty || size.width <= _leftPadding + _rightPadding) {
      _paintEmptyMessage(canvas, size);
      return;
    }

    final distances = _cumulativeDistances(valid);
    final altitudes = valid.map((p) => p.altitude).toList();

    var minAltitude = altitudes.reduce(math.min);
    var maxAltitude = altitudes.reduce(math.max);
    if ((maxAltitude - minAltitude).abs() < 1e-6) {
      // Evita una escala de altura nula cuando todos los puntos son iguales.
      minAltitude -= 1.0;
      maxAltitude += 1.0;
    } else {
      final margin = (maxAltitude - minAltitude) * 0.1;
      minAltitude -= margin;
      maxAltitude += margin;
    }

    var maxDistance = distances.isEmpty ? 0.0 : distances.last;
    if (maxDistance <= 0) {
      // Perfil con un solo punto o puntos coincidentes: usa un ancho ficticio.
      maxDistance = 1.0;
    }

    const chartLeft = _leftPadding;
    final chartRight = size.width - _rightPadding;
    const chartTop = _topPadding;
    final chartBottom = size.height - _bottomPadding;
    final chartWidth = chartRight - chartLeft;
    final chartHeight = chartBottom - chartTop;

    if (chartWidth <= 0 || chartHeight <= 0) {
      _paintEmptyMessage(canvas, size);
      return;
    }

    double xFor(double distance) =>
        chartLeft + (distance / maxDistance) * chartWidth;
    double yFor(double altitude) =>
        chartBottom -
        ((altitude - minAltitude) / (maxAltitude - minAltitude)) * chartHeight;

    _paintGrid(
      canvas,
      chartLeft,
      chartRight,
      chartTop,
      chartBottom,
      minAltitude,
      maxAltitude,
      distances,
      maxDistance,
    );

    final path = Path();
    for (var i = 0; i < valid.length; i++) {
      final x = xFor(distances[i]);
      final y = yFor(altitudes[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Área rellena con degradado.
    if (valid.length >= 2) {
      final fill = Path.from(path)
        ..lineTo(xFor(distances.last), chartBottom)
        ..lineTo(xFor(distances.first), chartBottom)
        ..close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: 0.35),
            lineColor.withValues(alpha: 0.02),
          ],
        ).createShader(
          Rect.fromLTRB(chartLeft, chartTop, chartRight, chartBottom),
        );
      canvas.drawPath(fill, fillPaint);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeJoin = StrokeJoin.round,
    );

    // Marcadores de cada vértice, útil con pocos puntos.
    final markerPaint = Paint()..color = lineColor;
    for (var i = 0; i < valid.length; i++) {
      canvas.drawCircle(
        Offset(xFor(distances[i]), yFor(altitudes[i])),
        2.5,
        markerPaint,
      );
    }
  }

  void _paintGrid(
    Canvas canvas,
    double left,
    double right,
    double top,
    double bottom,
    double minAltitude,
    double maxAltitude,
    List<double> distances,
    double maxDistance,
  ) {
    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1.0;

    const rows = 4;
    for (var i = 0; i <= rows; i++) {
      final t = i / rows;
      final y = bottom - t * (bottom - top);
      canvas.drawLine(Offset(left, y), Offset(right, y), axisPaint);

      final altitude = minAltitude + (maxAltitude - minAltitude) * t;
      _paintText(
        canvas,
        '${altitude.toStringAsFixed(0)} m',
        Offset(0, y - 6),
        maxWidth: left - 6,
        align: TextAlign.right,
      );
    }

    // Eje Y y eje X.
    canvas.drawLine(Offset(left, top), Offset(left, bottom), axisPaint);
    canvas.drawLine(Offset(left, bottom), Offset(right, bottom), axisPaint);

    _paintText(
      canvas,
      '0 m',
      Offset(left, bottom + 8),
      align: TextAlign.left,
    );
    if (maxDistance > 1.0 || distances.length > 1) {
      _paintText(
        canvas,
        _formatDistance(maxDistance),
        Offset(left, bottom + 8),
        maxWidth: right - left + _leftPadding,
        align: TextAlign.right,
      );
    }
  }

  void _paintText(
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
        text: 'Sin datos de altitud',
        style: TextStyle(color: labelColor, fontSize: 12),
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

  List<double> _cumulativeDistances(List<GeoPoint> pts) {
    final distances = <double>[0.0];
    for (var i = 1; i < pts.length; i++) {
      distances.add(
        distances[i - 1] + DistanceCalculator.haversine(pts[i - 1], pts[i]),
      );
    }
    return distances;
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }

  @override
  bool shouldRepaint(covariant _ElevationProfilePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.maxAccuracy != maxAccuracy ||
        oldDelegate.lineColor != lineColor;
  }
}
