// Límite del departamento del Putumayo como capa tenue de fondo.
// Fuente: GADM v4.1 nivel 1 (Colombia), simplificado para zoom
// departamental. Uso académico con atribución a GADM.
// El archivo vive en assets/geo/putumayo.geojson (ver pubspec.yaml).

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Ruta del GeoJSON del límite departamental empaquetado en la app.
const String putumayoGeoJsonAsset = 'assets/geo/putumayo.geojson';

/// Parsea un GeoJSON (FeatureCollection con Polygon/MultiPolygon) y
/// devuelve los anillos como listas de [LatLng].
/// Las coordenadas GeoJSON vienen en orden [longitud, latitud].
List<List<LatLng>> parsePutumayoBoundary(String geoJsonText) {
  final decoded = jsonDecode(geoJsonText) as Map<String, dynamic>;
  final features = decoded['features'] as List;
  final rings = <List<LatLng>>[];

  List<LatLng> toRing(List ring) {
    return [
      for (final coord in ring)
        LatLng(
          (coord as List)[1] as double,
          coord[0] as double,
        ),
    ];
  }

  for (final feature in features) {
    final geometry = (feature as Map<String, dynamic>)['geometry']
        as Map<String, dynamic>;
    final type = geometry['type'] as String;
    final coordinates = geometry['coordinates'] as List;
    if (type == 'Polygon') {
      for (final ring in coordinates) {
        rings.add(toRing(ring as List));
      }
    } else if (type == 'MultiPolygon') {
      for (final polygon in coordinates) {
        for (final ring in polygon as List) {
          rings.add(toRing(ring as List));
        }
      }
    }
  }
  return rings;
}

/// Carga el límite del Putumayo desde los assets de la app.
Future<List<List<LatLng>>> loadPutumayoBoundary() async {
  final text = await rootBundle.loadString(putumayoGeoJsonAsset);
  return parsePutumayoBoundary(text);
}

/// Capa tenue con el límite departamental para dar contexto geográfico.
/// No muestra nada mientras carga o si el asset falta.
class PutumayoBoundaryLayer extends StatelessWidget {
  const PutumayoBoundaryLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<List<LatLng>>>(
      future: loadPutumayoBoundary(),
      builder: (context, snapshot) {
        final rings = snapshot.data;
        if (rings == null || rings.isEmpty) {
          return const SizedBox.shrink();
        }
        return PolygonLayer(
          polygons: [
            for (final ring in rings)
              Polygon(
                points: ring,
                color: const Color(0x1A795548),
                borderColor: const Color(0xFF795548),
                borderStrokeWidth: 2,
              ),
          ],
        );
      },
    );
  }
}
