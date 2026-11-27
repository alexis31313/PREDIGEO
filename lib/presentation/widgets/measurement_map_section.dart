import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/geo_point.dart';
import '../providers/connectivity_provider.dart';
import 'measurement_map_view.dart';
import 'terrain_relief_toggle_view.dart';

/// Sección que alterna automáticamente entre el mapa de OpenStreetMap (modo
/// conectado) y la vista de relieve local (modo sin conexión).
///
/// La conmutación es transparente para la pantalla que la usa: basta con
/// proporcionar los puntos. [mapBuilder] permite inyectar una vista de mapa
/// alternativa (usada en las pruebas para no depender de la plataforma).
///
/// En modo sin conexión se puede alternar entre la vista plana (2D) y la vista
/// 3D generada localmente desde los puntos capturados.
class MeasurementMapSection extends ConsumerWidget {
  final List<GeoPoint> points;
  final List<GeoPoint> interiorPoints;
  final bool closePolygon;
  final double maxAccuracy;
  final Widget Function(List<GeoPoint> points, bool closePolygon)? mapBuilder;

  const MeasurementMapSection({
    super.key,
    required this.points,
    this.interiorPoints = const <GeoPoint>[],
    this.closePolygon = true,
    this.maxAccuracy = 20.0,
    this.mapBuilder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final content = isOnline
        ? Stack(
            children: [
              Positioned.fill(
                child: mapBuilder?.call(points, closePolygon) ??
                    MeasurementMapView(
                      points: points,
                      closePolygon: closePolygon,
                    ),
              ),
              Positioned(
                left: 8,
                bottom: 8,
                child: FilledButton.tonalIcon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      fullscreenDialog: true,
                      builder: (_) => TerrainRelief3DScreen(
                        points: points,
                        interiorPoints: interiorPoints,
                        closePolygon: closePolygon,
                        maxAccuracy: maxAccuracy,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.threed_rotation, size: 18),
                  label: const Text('Relieve 3D'),
                ),
              ),
            ],
          )
        : _OfflineRelief(
            points: points,
            interiorPoints: interiorPoints,
            closePolygon: closePolygon,
            maxAccuracy: maxAccuracy,
          );
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      child: KeyedSubtree(
        key: ValueKey(isOnline),
        child: content,
      ),
    );
  }
}

class _OfflineRelief extends StatelessWidget {
  final List<GeoPoint> points;
  final List<GeoPoint> interiorPoints;
  final bool closePolygon;
  final double maxAccuracy;

  const _OfflineRelief({
    required this.points,
    this.interiorPoints = const <GeoPoint>[],
    required this.closePolygon,
    required this.maxAccuracy,
  });

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
          child: TerrainReliefToggleView(
            points: points,
            interiorPoints: interiorPoints,
            closePolygon: closePolygon,
            maxAccuracy: maxAccuracy,
          ),
        ),
      ],
    );
  }
}
