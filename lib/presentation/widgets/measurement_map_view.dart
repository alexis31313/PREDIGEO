import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/entities/geo_point.dart';
import '../providers/map_style_provider.dart';

/// Color verde corporativo de PrediGeo (#2E7D32).
const Color predigeoGreen = Color(0xFF2E7D32);

/// Color tierra para bordes y rellenos secundarios (#795548).
const Color predigeoEarth = Color(0xFF795548);

/// Coordenadas de Mocoa, Putumayo (centro por defecto cuando no hay puntos).
const LatLng mocoaCenter = LatLng(1.15, -76.65);

/// Nivel de zoom por defecto cuando el mapa se centra en Mocoa sin puntos.
const double mocoaDefaultZoom = 8.0;

/// URL base de los mosaicos OpenStreetMap.
const _osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

/// Atribución visible de OpenStreetMap.
const String _osmAttribution = '© OpenStreetMap contributors';

/// Utilidades de cámara para el mapa, independientes de la vista.
///
/// Se exponen como funciones puras para poder verificarlas sin renderizar el
/// mapa.
class MapCamera {
  MapCamera._();

  /// Centro del conjunto de puntos (promedio de latitud y longitud).
  ///
  /// Si no hay puntos, devuelve el centro de Mocoa.
  static LatLng center(List<GeoPoint> points) {
    if (points.isEmpty) return mocoaCenter;
    var latSum = 0.0;
    var lngSum = 0.0;
    for (final point in points) {
      latSum += point.latitude;
      lngSum += point.longitude;
    }
    return LatLng(latSum / points.length, lngSum / points.length);
  }

  /// Nivel de zoom aproximado para encuadrar los puntos en la pantalla.
  ///
  /// [viewportWidth] es el ancho disponible en píxeles lógicos. El cálculo
  /// asume teselas de 256 px y añade un margen del 40 %.
  static double zoom(List<GeoPoint> points, {double viewportWidth = 400.0}) {
    if (points.isEmpty) return mocoaDefaultZoom;
    if (points.length < 2) return 17.0;

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    final span = math.max(maxLat - minLat, maxLng - minLng) * 1.4;
    if (span <= 0) return 17.0;

    final zoom = math.log(viewportWidth * 360.0 / (256.0 * span)) / math.ln2;
    return zoom.clamp(3.0, 20.0);
  }
}

/// Widget de marcador con el título "Punto N" sobre un pin de color.
class _PointMarker extends StatelessWidget {
  final LatLng point;
  final int index;

  const _PointMarker({required this.point, required this.index});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: predigeoGreen,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            'Punto $index',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Icon(
          Icons.location_pin,
          color: predigeoGreen,
          size: 24,
        ),
      ],
    );
  }
}

/// Carga el límite del departamento de Putumayo desde el asset GeoJSON.
///
/// Devuelve una lista de [LatLng] con los vértices del polígono simplificado,
/// o una lista vacía si el asset no se puede leer.
Future<List<LatLng>> loadPutumayoBoundary() async {
  final jsonString = await rootBundle.loadString('assets/geo/putumayo.geojson');
  final data = jsonDecode(jsonString) as Map<String, dynamic>;
  final features = data['features'] as List<dynamic>;
  if (features.isEmpty) return <LatLng>[];

  final geometry = features.first['geometry'] as Map<String, dynamic>;
  final coordinates = geometry['coordinates'] as List<dynamic>;
  final ring = coordinates.first as List<dynamic>;

  return ring
      .map((coord) {
        final c = coord as List<dynamic>;
        if (c.length < 2) return null;
        return LatLng(c[1] as double, c[0] as double);
      })
      .whereType<LatLng>()
      .toList(growable: false);
}

/// Vista de mapa (OpenStreetMap vía flutter_map) con el polígono y sus vértices.
///
/// Centra la cámara en el área medida, dibuja el polígono cuando hay al menos
/// tres puntos y coloca un marcador "Punto N" por vértice. Incluye el límite
/// del departamento de Putumayo como capa de fondo tenue y permite alternar
/// entre vista normal y satelital.
///
/// Cuando no hay puntos, centra en Mocoa (1.15, -76.65) con zoom 8.
class MeasurementMapView extends ConsumerWidget {
  final List<GeoPoint> points;

  /// Si es `true`, cierra el polígono para rellenarlo.
  final bool closePolygon;

  const MeasurementMapView({
    super.key,
    required this.points,
    this.closePolygon = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final satellite = ref.watch(mapStyleProvider);
    final valid = points.where((p) => p.accuracy <= 20.0).toList();

    final center = MapCamera.center(valid);
    final zoomLevel = MapCamera.zoom(valid);

    final latLngs = valid
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList(growable: false);

    final markers = <Marker>[
      for (var i = 0; i < latLngs.length; i++)
        Marker(
          point: latLngs[i],
          width: 40,
          height: 40,
          child: _PointMarker(point: latLngs[i], index: i + 1),
        ),
    ];

    final polygons = <Polygon>[].toSet();
    if (closePolygon && latLngs.length >= 3) {
      polygons.add(
        Polygon(
          points: latLngs,
          color: predigeoGreen.withValues(alpha: 0.2),
          borderColor: predigeoGreen,
          borderStrokeWidth: 3,
        ),
      );
    }

    final tileUrl = satellite
        ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
        : _osmTileUrl;

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoomLevel,
          ),
          children: [
            // Capa de fondo: límite del Putumayo (cargada desde asset).
            FutureBuilder<List<LatLng>>(
              future: loadPutumayoBoundary(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox.shrink();
                }
                return PolygonLayer(
                  polygons: [
                    Polygon(
                      points: snapshot.data!,
                      color: predigeoEarth.withValues(alpha: 0.08),
                      borderColor: predigeoEarth.withValues(alpha: 0.4),
                      borderStrokeWidth: 1,
                    ),
                  ],
                );
              },
            ),
            // Capa de mosaicos (navegación con caché del navegador para uso offline parcial).
            if (satellite)
              TileLayer(
                urlTemplate: tileUrl,
                userAgentPackageName: 'com.digitallab.predigeo',
              )
            else
              TileLayer(
                urlTemplate: tileUrl,
                userAgentPackageName: 'com.digitallab.predigeo',
                maxZoom: 18,
                minZoom: 3,
              ),
            MarkerLayer(markers: markers),
            if (polygons.isNotEmpty) PolygonLayer(polygons: polygons.toList()),
            // Atribución visible de OpenStreetMap.
            if (!satellite)
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _osmAttribution,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
          ],
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            shape: const CircleBorder(),
            elevation: 2,
            child: IconButton(
              tooltip: satellite ? 'Vista normal' : 'Vista satelital',
              icon: Icon(satellite ? Icons.map_outlined : Icons.satellite_alt),
              onPressed: () => ref.read(mapStyleProvider.notifier).toggle(),
            ),
          ),
        ),
        // Banner de modo sin conexión (overlay inferior).
        if (!kIsWeb && valid.isEmpty)
          const Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: OfflineFallback(),
          ),
      ],
    );
  }
}

/// Overlay mostrado cuando no hay puntos válidos y el mapa está centrado en Mocoa.
class OfflineFallback extends StatelessWidget {
  const OfflineFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      color: predigeoEarth.withValues(alpha: 0.9),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text(
            'Mapa centrado en Mocoa, Putumayo',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
