// Render de relieve sobre el mapa de PrediGeo.
// Dibuja encima del mapa el perfil de altitud de los puntos capturados:
// silueta con subidas y bajadas, o línea plana si el terreno es planicie.
// Todo local, sin red: solo usa la altitud ya capturada por el GPS.

import 'package:flutter/material.dart';

import '../../domain/entities/geo_point.dart';
import '../../domain/usecases/geo/slope_correction.dart';

/// Tarjeta semitransparente con el mini-perfil de relieve.
///
/// Se coloca con [Positioned] sobre el [FlutterMap]. Si hay menos de 2
/// puntos no se muestra nada.
class MapElevationOverlay extends StatelessWidget {
  final List<GeoPoint> points;

  const MapElevationOverlay({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) return const SizedBox.shrink();

    final range = SlopeCorrection.altitudeRange(points);
    final gainLoss = SlopeCorrection.elevationGainLoss(points);
    final flat = SlopeCorrection.isFlat(points);
    var minAlt = points.first.altitude;
    var maxAlt = points.first.altitude;
    for (final point in points) {
      if (point.altitude < minAlt) minAlt = point.altitude;
      if (point.altitude > maxAlt) maxAlt = point.altitude;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                flat ? Icons.horizontal_rule : Icons.terrain,
                size: 16,
                color: const Color(0xFF2E7D32),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  flat
                      ? 'Planicie · desnivel ${range.toStringAsFixed(1)} m'
                      : 'Relieve · +${gainLoss.gain.toStringAsFixed(1)} m / '
                          '−${gainLoss.loss.toStringAsFixed(1)} m',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${minAlt.toStringAsFixed(0)}–${maxAlt.toStringAsFixed(0)} m',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 44,
            width: double.infinity,
            child: CustomPaint(
              painter: _MiniProfilePainter(
                altitudes: [for (final p in points) p.altitude],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniProfilePainter extends CustomPainter {
  final List<double> altitudes;

  _MiniProfilePainter({required this.altitudes});

  @override
  void paint(Canvas canvas, Size size) {
    if (altitudes.length < 2) return;
    var minAlt = altitudes.first;
    var maxAlt = altitudes.first;
    for (final alt in altitudes) {
      if (alt < minAlt) minAlt = alt;
      if (alt > maxAlt) maxAlt = alt;
    }
    final range = maxAlt - minAlt;

    Offset project(int index) {
      final x = altitudes.length == 1
          ? 0.0
          : index / (altitudes.length - 1) * size.width;
      final y = range == 0
          ? size.height / 2
          : size.height -
              4 -
              (altitudes[index] - minAlt) / range * (size.height - 8);
      return Offset(x, y);
    }

    final linePath = Path()..moveTo(0, project(0).dy);
    for (var i = 1; i < altitudes.length; i++) {
      linePath.lineTo(
        altitudes.length == 1
            ? 0.0
            : i / (altitudes.length - 1) * size.width,
        project(i).dy,
      );
    }
    final fillPath = Path.from(linePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()..color = const Color(0x332E7D32),
    );
    canvas.drawPath(
      linePath,
      Paint()
        ..color = const Color(0xFF795548)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // Punto inicial (verde) y final (tierra).
    canvas.drawCircle(project(0), 3.5, Paint()..color = const Color(0xFF2E7D32));
    canvas.drawCircle(
      project(altitudes.length - 1),
      3.5,
      Paint()..color = const Color(0xFF795548),
    );
  }

  @override
  bool shouldRepaint(covariant _MiniProfilePainter oldDelegate) {
    if (identical(this, oldDelegate)) return false;
    if (oldDelegate.altitudes.length != altitudes.length) return true;
    for (var i = 0; i < altitudes.length; i++) {
      if (oldDelegate.altitudes[i] != altitudes[i]) return true;
    }
    return false;
  }
}
