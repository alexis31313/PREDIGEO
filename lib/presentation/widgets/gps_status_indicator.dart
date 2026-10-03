// Widget que indica la calidad de la señal GPS
// con un indicador de color.

import 'package:flutter/material.dart';

enum GpsSignalQuality { none, poor, fair, good, excellent }

class GpsStatusIndicator extends StatelessWidget {
  final GpsSignalQuality quality;
  final double size;

  const GpsStatusIndicator({
    super.key,
    required this.quality,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getColor(),
            boxShadow: [
              BoxShadow(
                color: _getColor().withValues(alpha: 0.4),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _getLabel(),
          style: TextStyle(
            fontSize: 13,
            color: _getColor(),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getColor() {
    switch (quality) {
      case GpsSignalQuality.none:
        return Colors.red;
      case GpsSignalQuality.poor:
        return Colors.orange;
      case GpsSignalQuality.fair:
        return Colors.yellow.shade700;
      case GpsSignalQuality.good:
        return Colors.lightGreen;
      case GpsSignalQuality.excellent:
        return Colors.green;
    }
  }

  String _getLabel() {
    switch (quality) {
      case GpsSignalQuality.none:
        return 'Sin señal';
      case GpsSignalQuality.poor:
        return 'Señal débil';
      case GpsSignalQuality.fair:
        return 'Señal regular';
      case GpsSignalQuality.good:
        return 'Señal buena';
      case GpsSignalQuality.excellent:
        return 'Señal excelente';
    }
  }
}
