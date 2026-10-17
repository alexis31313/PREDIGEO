import 'package:flutter/material.dart';

import '../../domain/entities/geo_point.dart';

class TerrainReliefView extends StatelessWidget {
  final List<GeoPoint> points;

  const TerrainReliefView({
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

    return Column(
      children: [
        SizedBox(
          height: 160,
          width: double.infinity,
          child: CustomPaint(
            painter: _TerrainReliefPainter(
              points: points,
              lineColor: Theme.of(context).colorScheme.primary,
              fillColor: Theme.of(context).colorScheme.primaryContainer,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _AltitudeBadge(
              label: 'Mín',
              value: points
                  .map((p) => p.altitude)
                  .reduce((a, b) => a < b ? a : b),
              color: Colors.blue,
            ),
            _AltitudeBadge(
              label: 'Máx',
              value: points
                  .map((p) => p.altitude)
                  .reduce((a, b) => a > b ? a : b),
              color: Colors.red,
            ),
          ],
        ),
      ],
    );
  }
}

class _TerrainReliefPainter extends CustomPainter {
  final List<GeoPoint> points;
  final Color lineColor;
  final Color fillColor;

  _TerrainReliefPainter({
    required this.points,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final altitudes = points.map((p) => p.altitude).toList();
    final minAlt = altitudes.reduce((a, b) => a < b ? a : b);
    final maxAlt = altitudes.reduce((a, b) => a > b ? a : b);
    final range = maxAlt - minAlt;

    final baselineY = size.height * 0.85;
    final maxY = size.height * 0.7;

    final path = Path();
    final fillPath = Path();

    for (var i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final normalizedAlt = range == 0 ? 0.5 : (points[i].altitude - minAlt) / range;
      final y = baselineY - (normalizedAlt * (baselineY - maxY));

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, baselineY);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, baselineY);
    fillPath.close();

    final fillPaint = Paint()
      ..color = fillColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, strokePaint);

    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    for (var i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final normalizedAlt = range == 0 ? 0.5 : (points[i].altitude - minAlt) / range;
      final y = baselineY - (normalizedAlt * (baselineY - maxY));
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }

    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    for (var i = 0; i <= 4; i++) {
      final y = baselineY - (i / 4) * (baselineY - maxY);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TerrainReliefPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor;
  }
}

class _AltitudeBadge extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _AltitudeBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ${value.toStringAsFixed(1)} m',
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }
}
