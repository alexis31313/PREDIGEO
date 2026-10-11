import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/geo_point.dart';
import '../providers/connectivity_provider.dart';
import 'measurement_map_view.dart';
import 'terrain_relief_view.dart';

/// Sección que alterna automáticamente entre el mapa de Google Maps (modo
/// conectado) y la vista de relieve local (modo sin conexión).
///
/// La conmutación es transparente para la pantalla que la usa: basta con
/// proporcionar los puntos. [mapBuilder] permite inyectar una vista de mapa
/// alternativa (usada en las pruebas para no depender de la plataforma).
class MeasurementMapSection extends ConsumerWidget {
  final List<GeoPoint> points;
  final bool closePolygon;
  final Widget Function(List<GeoPoint> points, bool closePolygon)? mapBuilder;

  const MeasurementMapSection({
    super.key,
    required this.points,
    this.closePolygon = true,
    this.mapBuilder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    if (isOnline) {
      return mapBuilder?.call(points, closePolygon) ??
          MeasurementMapView(points: points, closePolygon: closePolygon);
    }

    return _OfflineRelief(points: points, closePolygon: closePolygon);
  }
}

class _OfflineRelief extends StatelessWidget {
  final List<GeoPoint> points;
  final bool closePolygon;

  const _OfflineRelief({required this.points, required this.closePolygon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.cloud_off,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Vista de relieve (sin conexión)',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: TerrainReliefView(
            points: points,
            closePolygon: closePolygon,
          ),
        ),
      ],
    );
  }
}
