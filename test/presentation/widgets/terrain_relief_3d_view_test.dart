import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:predigeo/domain/entities/geo_point.dart';
import 'package:predigeo/domain/usecases/geo/terrain_surface.dart';
import 'package:predigeo/presentation/widgets/terrain_relief_3d_view.dart';

import '../../support/fixtures.dart';

void main() {
  Future<void> pumpView(
    WidgetTester tester,
    TerrainSurface surface, {
    double? exaggeration = 2.0,
    bool wireframe = false,
    bool contours = false,
    bool smooth = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              height: 260,
              child: TerrainRelief3DView(
                surface: surface,
                verticalExaggeration: exaggeration,
                showWireframe: wireframe,
                showContours: contours,
                smooth: smooth,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  TerrainSurface polygonSurface(List<GeoPoint> points) {
    return TerrainSurface(
      kind: TerrainSurfaceKind.polygon,
      vertices: List<GeoPoint>.of(points),
      triangles: [
        [points[0], points[1], points[2]],
        [points[0], points[2], points[3]],
      ],
    );
  }

  /// Superficie real con relieve (contorno + punto interior elevado).
  TerrainSurface hillSurface() {
    final contour = <GeoPoint>[
      buildPoint(seq: 0, latitude: 1.15380, longitude: -76.65100, altitude: 430),
      buildPoint(seq: 1, latitude: 1.15380, longitude: -76.65060, altitude: 431),
      buildPoint(seq: 2, latitude: 1.15420, longitude: -76.65060, altitude: 433),
      buildPoint(seq: 3, latitude: 1.15420, longitude: -76.65100, altitude: 432),
    ];
    final interior = <GeoPoint>[
      buildPoint(seq: 0, latitude: 1.15400, longitude: -76.65080, altitude: 440),
    ];
    return TerrainSurfaceCalculator().fromPoints(
      contour,
      interiorPoints: interior,
      clipToBoundary: true,
    );
  }

  group('TerrainRelief3DView', () {
    testWidgets('renderiza la malla 3D con una superficie valida',
        (tester) async {
      await pumpView(tester, polygonSurface(buildPolygonPoints()));

      expect(tester.takeException(), isNull);
      expect(find.byType(TerrainRelief3DView), findsOneWidget);
      expect(find.text('Exageración vertical: 2.0x'), findsOneWidget);
    });

    testWidgets('la exageración automática se indica en la leyenda',
        (tester) async {
      await pumpView(tester, hillSurface(), exaggeration: null);

      expect(tester.takeException(), isNull);
      expect(find.textContaining('(auto)'), findsOneWidget);
    });

    testWidgets('muestra un mensaje cuando la superficie no esta disponible',
        (tester) async {
      await pumpView(
        tester,
        TerrainSurface(
          kind: TerrainSurfaceKind.unavailable,
          vertices: [],
          triangles: [],
          reason: 'sin superficie',
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
          find.textContaining('Sin superficie 3D disponible.'), findsOneWidget);
    });

    testWidgets('muestra un mensaje cuando la superficie es track',
        (tester) async {
      await pumpView(
        tester,
        TerrainSurface(
          kind: TerrainSurfaceKind.track,
          vertices: const [],
          triangles: const [],
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Sin superficie 3D disponible para este track.'),
          findsOneWidget);
    });

    testWidgets('muestra el aviso de precisión en la vista valida',
        (tester) async {
      await pumpView(tester, polygonSurface(buildPolygonPoints()));

      expect(find.text(terrainAccuracyDisclaimer), findsOneWidget);
    });

    testWidgets('avisa cuando la superficie es plana', (tester) async {
      await pumpView(tester, polygonSurface(buildPolygonPoints()));

      expect(find.textContaining('Sin variación de altitud'), findsOneWidget);
    });

    testWidgets('dibuja malla, curvas y suavizado sin errores',
        (tester) async {
      await pumpView(
        tester,
        hillSurface(),
        wireframe: true,
        contours: true,
        smooth: true,
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Curvas:'), findsOneWidget);
    });

    testWidgets('rota con un dedo, hace zoom con dos y se restablece',
        (tester) async {
      await pumpView(tester, hillSurface());
      final center = tester.getCenter(find.byType(TerrainRelief3DView));

      await tester.dragFrom(center, const Offset(80, 40));
      await tester.pump();

      final first = await tester.startGesture(center - const Offset(30, 0));
      final second = await tester.startGesture(center + const Offset(30, 0),
          pointer: 7);
      await first.moveBy(const Offset(-30, 0));
      await second.moveBy(const Offset(30, 0));
      await first.up();
      await second.up();
      await tester.pump();

      await tester.tap(find.byTooltip('Restablecer vista 3D'));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('el arrastre dentro de la vista no desplaza el scroll padre',
        (tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              controller: controller,
              children: [
                SizedBox(
                  height: 300,
                  child: TerrainRelief3DView(surface: hillSurface()),
                ),
                const SizedBox(height: 2000),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(TerrainRelief3DView), const Offset(0, -150));
      await tester.pumpAndSettle();

      expect(controller.offset, 0);
    });
  });
}
