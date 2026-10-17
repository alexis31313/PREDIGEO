import 'package:flutter/material.dart';

import '../../domain/entities/geo_point.dart';

class ElevationProfileChart extends StatelessWidget {
  final List<GeoPoint> points;

  const ElevationProfileChart({
    super.key,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Center(
        child: Text('Sin datos de elevación'),
      );
    }

    final altitudes = points.map((p) => p.altitude).toList();
    final minAlt = altitudes.reduce((a, b) => a < b ? a : b);
    final maxAlt = altitudes.reduce((a, b) => a > b ? a : b);
    final avgAlt = altitudes.reduce((a, b) => a + b) / altitudes.length;

    return Column(
      children: [
        SizedBox(
          height: 200,
          width: double.infinity,
          child: CustomPaint(
            painter: _ElevationChartPainter(
              points: points,
              lineColor: Theme.of(context).colorScheme.primary,
              gridColor: Colors.grey.withValues(alpha: 0.3),
              textColor: Colors.grey[600]!,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatBadge(label: 'Mín', value: minAlt, color: Colors.blue),
            _StatBadge(label: 'Prom', value: avgAlt, color: Colors.green),
            _StatBadge(label: 'Máx', value: maxAlt, color: Colors.red),
          ],
        ),
      ],
    );
  }
}

class _ElevationChartPainter extends CustomPainter {
  final List<GeoPoint> points;
  final Color lineColor;
  final Color gridColor;
  final Color textColor;

  _ElevationChartPainter({
    required this.points,
    required this.lineColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const leftPad = 50.0;
    const rightPad = 10.0;
    const topPad = 10.0;
    const bottomPad = 30.0;

    final chartWidth = size.width - leftPad - rightPad;
    final chartHeight = size.height - topPad - bottomPad;

    final altitudes = points.map((p) => p.altitude).toList();
    final minAlt = altitudes.reduce((a, b) => a < b ? a : b);
    final maxAlt = altitudes.reduce((a, b) => a > b ? a : b);
    final range = maxAlt - minAlt;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    for (var i = 0; i <= 4; i++) {
      final y = topPad + (i / 4) * chartHeight;
      canvas.drawLine(Offset(leftPad, y), Offset(size.width - rightPad, y), gridPaint);

      final value = maxAlt - (i / 4) * (range == 0 ? 1 : range);
      final textSpan = TextSpan(
        text: value.toStringAsFixed(0),
        style: TextStyle(color: textColor, fontSize: 10),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(2, y - textPainter.height / 2));
    }

    for (var i = 0; i < points.length; i++) {
      final xStep = points.length > 1 ? chartWidth / (points.length - 1) : 0.0;
      final x = leftPad + i * xStep;

      if (i % (points.length > 10 ? (points.length / 5).ceil() : 1) == 0 ||
          i == points.length - 1) {
        final textSpan = TextSpan(
          text: '$i',
          style: TextStyle(color: textColor, fontSize: 10),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, size.height - bottomPad + 4),
        );
      }
    }

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final xStep = points.length > 1 ? chartWidth / (points.length - 1) : 0.0;
      final x = leftPad + i * xStep;
      final normalizedAlt = range == 0 ? 0.5 : (points[i].altitude - minAlt) / range;
      final y = topPad + chartHeight - (normalizedAlt * chartHeight);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final strokePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, strokePaint);

    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    for (var i = 0; i < points.length; i++) {
      final xStep = points.length > 1 ? chartWidth / (points.length - 1) : 0.0;
      final x = leftPad + i * xStep;
      final normalizedAlt = range == 0 ? 0.5 : (points[i].altitude - minAlt) / range;
      final y = topPad + chartHeight - (normalizedAlt * chartHeight);
      canvas.drawCircle(Offset(x, y), 3.5, dotPaint);
    }

    final axisPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(leftPad, topPad),
      Offset(leftPad, topPad + chartHeight),
      axisPaint,
    );
    canvas.drawLine(
      Offset(leftPad, topPad + chartHeight),
      Offset(size.width - rightPad, topPad + chartHeight),
      axisPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ElevationChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.textColor != textColor;
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            '${value.toStringAsFixed(1)} m',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
