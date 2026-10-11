import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../domain/entities/geo_point.dart';
import '../providers/map_style_provider.dart';

/// Utilidades de cámara para el mapa, independientes de la vista.
///
/// Se exponen como funciones puras para poder verificarlas sin renderizar el
/// mapa.
class MapCamera {
  MapCamera._();

  /// Centro del conjunto de puntos (promedio de latitud y longitud).
  static LatLng center(List<GeoPoint> points) {
    if (points.isEmpty) return const LatLng(0, 0);
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

/// Vista de mapa (Google Maps) con el polígono y sus vértices.
///
/// Centra la cámara en el área medida, dibuja el polígono cuando hay al menos
/// tres puntos y coloca un marcador numerado por vértice. Permite alternar
/// entre vista normal y satelital; la elección se persiste localmente.
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
    if (valid.isEmpty) {
      return const Center(child: Text('Sin puntos para mostrar en el mapa'));
    }

    final latLngs = valid
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList(growable: false);

    final markers = <Marker>{
      for (var i = 0; i < latLngs.length; i++)
        Marker(
          markerId: MarkerId('punto_$i'),
          position: latLngs[i],
          infoWindow: InfoWindow(title: 'Punto ${i + 1}'),
        ),
    };

    final polygons = <Polygon>{};
    if (closePolygon && latLngs.length >= 3) {
      polygons.add(
        Polygon(
          polygonId: const PolygonId('poligono'),
          points: latLngs,
          strokeColor: Theme.of(context).colorScheme.primary,
          strokeWidth: 3,
          fillColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        ),
      );
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: MapCamera.center(valid),
            zoom: MapCamera.zoom(valid),
          ),
          mapType: satellite ? MapType.satellite : MapType.normal,
          markers: markers,
          polygons: polygons,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
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
      ],
    );
  }
}
