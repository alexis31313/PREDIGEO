// Vista de mapa de una medición (modo conectado).
// Usa flutter_map + mosaicos de OpenStreetMap (sin llave de API):
// polígono para áreas, polilínea para trayectos, un marcador por punto
// y el límite del Putumayo como fondo tenue. Sin puntos centra en Mocoa.
// Sin conexión o sin puntos muestra un respaldo offline: la captura y el
// cálculo nunca dependen del mapa (offline-first).

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/entities/geo_point.dart';
import '../../domain/entities/measurement_enums.dart';
import 'map_elevation_overlay.dart';
import 'putumayo_boundary.dart';

/// Mapa de una medición. Solo tiene sentido en modo conectado.
class MeasurementMapView extends StatelessWidget {
  /// Puntos capturados en orden.
  final List<GeoPoint> points;

  /// Tipo de medición: define polígono (área) o polilínea (trayecto).
  final MeasurementType type;

  /// `false` en modo sin conexión: muestra el respaldo offline.
  final bool online;

  /// Altura del mapa en píxeles.
  final double height;

  /// Centro del departamento del Putumayo (Mocoa) para vista sin puntos.
  static const LatLng mocoaCenter = LatLng(1.15, -76.65);

  const MeasurementMapView({
    super.key,
    required this.points,
    required this.type,
    required this.online,
    this.height = 240,
  });

  @override
  Widget build(BuildContext context) {
    if (!online) {
      return _OfflineFallback(height: height);
    }
    if (points.isEmpty) {
      return SizedBox(
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              FlutterMap(
                options: const MapOptions(
                  initialCenter: mocoaCenter,
                  initialZoom: 8,
                ),
                children: const [
                  _OsmTileLayer(),
                  PutumayoBoundaryLayer(),
                ],
              ),
              const Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: _MocoaLabel(),
              ),
            ],
          ),
        ),
      );
    }

    final latLngs = [
      for (final p in points) LatLng(p.latitude, p.longitude),
    ];

    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: latLngs.first,
                initialZoom: 16,
              ),
              children: [
                const _OsmTileLayer(),
                const PutumayoBoundaryLayer(),
                if (type == MeasurementType.area && latLngs.length >= 3)
                  PolygonLayer(
                    polygons: [
                      Polygon(
                        points: latLngs,
                        color: const Color(0x332E7D32),
                        borderColor: const Color(0xFF2E7D32),
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                if (type == MeasurementType.path || latLngs.length < 3)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: latLngs,
                        color: const Color(0xFF2E7D32),
                        strokeWidth: 4,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    for (var i = 0; i < latLngs.length; i++)
                      Marker(
                        point: latLngs[i],
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        child: _PointBadge(number: i + 1),
                      ),
                  ],
                ),
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('© OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
            // Render de relieve dimensionado sobre el mapa.
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: MapElevationOverlay(points: points),
            ),
          ],
        ),
      ),
    );
  }
}

/// Capa de mosaicos OSM con identificación y caché de navegación.
///
/// El caché integrado evita repetir descargas de lo ya visitado (con
/// internet se guarda, en campo se reutiliza) y respeta la política de
/// uso de OpenStreetMap: sin descargas masivas.
class _OsmTileLayer extends StatelessWidget {
  const _OsmTileLayer();

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.digitallab.predigeo',
      maxNativeZoom: 19,
      tileProvider: NetworkTileProvider(
        cachingProvider: BuiltInMapCachingProvider.getOrCreateInstance(
          maxCacheSize: 256 * 1024 * 1024,
        ),
      ),
    );
  }
}

/// Insignia numerada de cada punto capturado (reemplaza el InfoWindow).
class _PointBadge extends StatelessWidget {
  final int number;

  const _PointBadge({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          '$number',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _MocoaLabel extends StatelessWidget {
  const _MocoaLabel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Putumayo · Mocoa',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _OfflineFallback extends StatelessWidget {
  final double height;

  const _OfflineFallback({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 40, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Mapa disponible en modo conectado.\n'
              'La medición funciona sin conexión.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
