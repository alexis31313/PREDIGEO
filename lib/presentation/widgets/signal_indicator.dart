import 'package:flutter/material.dart';

class SignalIndicator extends StatelessWidget {
  final double? accuracy;

  const SignalIndicator({
    super.key,
    required this.accuracy,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final icon = _getIcon();
    final label = _getLabel();
    final valueText = _getValueText();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        if (valueText != null) ...[
          const SizedBox(width: 4),
          Text(
            valueText,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Color _getColor() {
    if (accuracy == null || accuracy == 0) {
      return Colors.grey;
    }
    if (accuracy! <= 3.0) {
      return Colors.green;
    }
    if (accuracy! <= 8.0) {
      return Colors.lightGreen;
    }
    if (accuracy! <= 15.0) {
      return Colors.orange;
    }
    return Colors.red;
  }

  IconData _getIcon() {
    if (accuracy == null || accuracy == 0) {
      return Icons.signal_cellular_connected_no_internet_0_bar;
    }
    if (accuracy! <= 3.0) {
      return Icons.signal_cellular_alt;
    }
    if (accuracy! <= 8.0) {
      return Icons.signal_cellular_alt;
    }
    if (accuracy! <= 15.0) {
      return Icons.signal_cellular_alt_2_bar;
    }
    return Icons.signal_cellular_alt_1_bar;
  }

  String _getLabel() {
    if (accuracy == null || accuracy == 0) {
      return 'Sin señal';
    }
    if (accuracy! <= 3.0) {
      return 'Excelente';
    }
    if (accuracy! <= 8.0) {
      return 'Buena';
    }
    if (accuracy! <= 15.0) {
      return 'Regular';
    }
    return 'Pobre';
  }

  String? _getValueText() {
    if (accuracy == null || accuracy == 0) {
      return null;
    }
    return '${accuracy!.toStringAsFixed(1)} m';
  }
}
