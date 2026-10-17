// Pruebas del límite del Putumayo: parseo del GeoJSON y asset empaquetado.
// El asset vive en assets/geo/putumayo.geojson (GADM v4.1 nivel 1,
// simplificado para zoom departamental, uso académico).

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:predigeo/presentation/widgets/putumayo_boundary.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('parsePutumayoBoundary', () {
    test('convierte Polygon de [lon, lat] a LatLng', () {
      const sample = '''
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{"name":"X"},
"geometry":{"type":"Polygon","coordinates":[
[[-76.65,1.15],[-76.64,1.15],[-76.64,1.16],[-76.65,1.15]]]}}]}''';

      final rings = parsePutumayoBoundary(sample);

      expect(rings.length, 1);
      expect(rings.first.length, 4);
      // GeoJSON [lon, lat] → LatLng(lat, lon).
      expect(rings.first.first.latitude, 1.15);
      expect(rings.first.first.longitude, -76.65);
    });

    test('convierte MultiPolygon con varios anillos', () {
      const sample = '''
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{"name":"X"},
"geometry":{"type":"MultiPolygon","coordinates":[
[[[-76.65,1.15],[-76.64,1.15],[-76.65,1.15]]],
[[[-76.60,1.10],[-76.59,1.10],[-76.60,1.10]]] ]}}]}''';

      final rings = parsePutumayoBoundary(sample);

      expect(rings.length, 2);
    });
  });

  group('asset assets/geo/putumayo.geojson', () {
    test('existe, es el Putumayo y cubre Mocoa', () async {
      final text = await rootBundle.loadString(putumayoGeoJsonAsset);
      final rings = parsePutumayoBoundary(text);

      expect(rings, isNotEmpty);
      final vertices = rings.fold<int>(0, (sum, ring) => sum + ring.length);
      expect(vertices, greaterThan(100));

      final lons = [for (final r in rings) for (final p in r) p.longitude];
      final lats = [for (final r in rings) for (final p in r) p.latitude];
      final minLon = lons.reduce((a, b) => a < b ? a : b);
      final maxLon = lons.reduce((a, b) => a > b ? a : b);
      final minLat = lats.reduce((a, b) => a < b ? a : b);
      final maxLat = lats.reduce((a, b) => a > b ? a : b);

      // Mocoa (1.15, -76.65) debe quedar dentro del bbox.
      expect(minLon, lessThan(-76.65));
      expect(maxLon, greaterThan(-76.65));
      expect(minLat, lessThan(1.15));
      expect(maxLat, greaterThan(1.15));
    });
  });
}
