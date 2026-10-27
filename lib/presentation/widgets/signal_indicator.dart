import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class SignalIndicator extends StatelessWidget {
  final double? accuracy;

  const SignalIndicator({super.key, required this.accuracy});

  @override
  Widget build(BuildContext context) {
    final color = _getColor(context);
    final icon = _getIcon();
    final label = _getLabel();
    final valueText = _getValueText();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          if (valueText != null) ...[
            const SizedBox(width: 4),
            Text(
              valueText,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Color _getColor(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = Theme.of(context).extension<AppStatusColors>();
    if (accuracy == null || accuracy == 0) {
      return colors.onSurfaceVariant;
    }
    if (accuracy! <= 3.0) {
      return status?.excellent ?? colors.primary;
    }
    if (accuracy! <= 8.0) {
      return status?.good ?? colors.secondary;
    }
    if (accuracy! <= 15.0) {
      return status?.regular ?? colors.tertiary;
    }
    return status?.poor ?? colors.error;
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
