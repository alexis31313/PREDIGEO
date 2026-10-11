// Pruebas de renderizado de las visualizaciones de relieve.
// Verifican que ambos widgets se dibujan sin errores, incluso con listas
// vacías o con un único punto.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:predigeo/presentation/widgets/elevation_profile_chart.dart';
import 'package:predigeo/presentation/widgets/terrain_relief_view.dart';

import '../../support/fixtures.dart';

void main() {
  Future<void> pumpWidget(WidgetTester tester, Widget child) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(width: 320, height: 220, child: child),
          ),
        ),
      ),
    );
  }

  group('ElevationProfileChart', () {
    testWidgets('renderiza con un polígono de varios puntos', (tester) async {
      await pumpWidget(
        tester,
        ElevationProfileChart(points: buildPolygonPoints()),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(ElevationProfileChart), findsOneWidget);
    });

    testWidgets('renderiza con una lista vacía', (tester) async {
      await pumpWidget(tester, const ElevationProfileChart(points: []));

      expect(tester.takeException(), isNull);
    });

    testWidgets('renderiza con un único punto', (tester) async {
      await pumpWidget(
        tester,
        ElevationProfileChart(points: [buildPoint(altitude: 420)]),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('TerrainReliefView', () {
    testWidgets('renderiza el polígono con varios puntos', (tester) async {
      await pumpWidget(
        tester,
        TerrainReliefView(points: buildPolygonPoints()),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(TerrainReliefView), findsOneWidget);
    });

    testWidgets('renderiza un trayecto abierto', (tester) async {
      final path = [
        buildPoint(seq: 0, latitude: 1.1538, longitude: -76.651),
        buildPoint(seq: 1, latitude: 1.1540, longitude: -76.6508),
        buildPoint(seq: 2, latitude: 1.1542, longitude: -76.6506),
      ];

      await pumpWidget(
        tester,
        TerrainReliefView(points: path, closePolygon: false),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('renderiza con una lista vacía', (tester) async {
      await pumpWidget(tester, const TerrainReliefView(points: []));

      expect(tester.takeException(), isNull);
    });

    testWidgets('renderiza con un único punto', (tester) async {
      await pumpWidget(
        tester,
        TerrainReliefView(points: [buildPoint(altitude: 420)]),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
