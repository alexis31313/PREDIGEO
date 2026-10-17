// Pruebas del mapa de medición con flutter_map + OpenStreetMap.
// Verifica el render con puntos, el overlay de relieve, el fallback
// offline y la vista del Putumayo sin puntos. No requieren internet:
// los mosaicos fallan en silencio y las capas se verifican en el árbol.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:predigeo/domain/entities/geo_point.dart';
import 'package:predigeo/domain/entities/measurement_enums.dart';
import 'package:predigeo/presentation/widgets/map_elevation_overlay.dart';
import 'package:predigeo/presentation/widgets/measurement_map_view.dart';

void main() {
  final baseTime = DateTime(2024, 1, 15, 10, 30);

  GeoPoint point(double lat, double lon, double alt, int seq) {
    return GeoPoint(
      seq: seq,
      latitude: lat,
      longitude: lon,
      altitude: alt,
      accuracy: 5.0,
      timestamp: baseTime,
    );
  }

  final areaPoints = [
    point(1.15, -76.65, 500.0, 0),
    point(1.151, -76.651, 510.0, 1),
    point(1.151, -76.65, 505.0, 2),
  ];

  final pathPoints = [
    point(1.15, -76.65, 500.0, 0),
    point(1.151, -76.651, 505.0, 1),
  ];

  Future<void> pumpMap(
    WidgetTester tester, {
    required List<GeoPoint> points,
    required MeasurementType type,
    required bool online,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MeasurementMapView(
            points: points,
            type: type,
            online: online,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('MeasurementMapView con puntos (online)', () {
    testWidgets('área: FlutterMap + polígono + marcadores + overlay',
        (tester) async {
      await pumpMap(
        tester,
        points: areaPoints,
        type: MeasurementType.area,
        online: true,
      );

      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byType(TileLayer), findsOneWidget);
      expect(find.byType(PolygonLayer), findsWidgets);
      expect(find.byType(MarkerLayer), findsOneWidget);
      expect(find.byType(MapElevationOverlay), findsOneWidget);

      final markers =
          tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers;
      expect(markers.length, areaPoints.length);
    });

    testWidgets('trayecto: polilínea en vez de polígono de medición',
        (tester) async {
      await pumpMap(
        tester,
        points: pathPoints,
        type: MeasurementType.path,
        online: true,
      );

      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byType(PolylineLayer), findsOneWidget);
      // Solo el límite del Putumayo puede aportar polígonos de fondo.
      final polygonLayers = tester
          .widgetList<PolygonLayer>(find.byType(PolygonLayer))
          .toList();
      for (final layer in polygonLayers) {
        for (final polygon in layer.polygons) {
          expect(polygon.points.length, greaterThan(10));
        }
      }
    });

    testWidgets('atribución OSM presente', (tester) async {
      await pumpMap(
        tester,
        points: areaPoints,
        type: MeasurementType.area,
        online: true,
      );

      final attribution = tester.widget<RichAttributionWidget>(
        find.byType(RichAttributionWidget),
      );
      final texts = attribution.attributions
          .whereType<TextSourceAttribution>()
          .map((a) => a.text);
      expect(texts, contains('© OpenStreetMap contributors'));
    });

    testWidgets('overlay muestra relieve con subidas y bajadas',
        (tester) async {
      await pumpMap(
        tester,
        points: areaPoints,
        type: MeasurementType.area,
        online: true,
      );

      expect(find.textContaining('Relieve'), findsOneWidget);
    });
  });

  group('MeasurementMapView sin conexión o sin puntos', () {
    testWidgets('offline: muestra el fallback y no el mapa', (tester) async {
      await pumpMap(
        tester,
        points: areaPoints,
        type: MeasurementType.area,
        online: false,
      );

      expect(find.byType(FlutterMap), findsNothing);
      expect(
        find.text('Mapa disponible en modo conectado.\n'
            'La medición funciona sin conexión.'),
        findsOneWidget,
      );
    });

    testWidgets('sin puntos: centra en Mocoa con etiqueta del Putumayo',
        (tester) async {
      await pumpMap(tester, points: [], type: MeasurementType.area, online: true);

      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.text('Putumayo · Mocoa'), findsOneWidget);
      expect(find.byType(MapElevationOverlay), findsNothing);
    });
  });
}
