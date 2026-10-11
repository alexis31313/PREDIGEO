// Widget reutilizable para mostrar una tarjeta de medición
// con nombre, fecha, área, distancia y tipo.

import 'package:flutter/material.dart';

class MeasurementCard extends StatelessWidget {
  final String name;
  final DateTime date;
  final double area;
  final double distance;
  final String type;
  final VoidCallback? onTap;

  const MeasurementCard({
    super.key,
    required this.name,
    required this.date,
    required this.area,
    required this.distance,
    required this.type,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _formatDate(date),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.square_foot, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${area.toStringAsFixed(2)} m²',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 20),
                  Icon(Icons.straighten, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${distance.toStringAsFixed(2)} m',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}
