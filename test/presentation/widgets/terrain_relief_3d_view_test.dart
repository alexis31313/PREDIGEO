import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:predigeo/domain/entities/geo_point.dart';
import 'package:predigeo/domain/usecases/geo/terrain_surface.dart';
import 'package:predigeo/presentation/widgets/terrain_relief_3d_view.dart';

import '../../support/fixtures.dart';

void main() {
  Future<void> pumpView(WidgetTester tester, TerrainSurface surface) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              height: 220,
              child: TerrainRelief3DView(surface: surface),
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

  group('TerrainRelief3DView', () {
    testWidgets('renderiza la malla 3D con una superficie valida', (tester) async {
      final points = buildPolygonPoints();
      final surface = polygonSurface(points);

      await pumpView(tester, surface);

      expect(tester.takeException(), isNull);
      expect(find.byType(TerrainRelief3DView), findsOneWidget);
      expect(find.text('Exageración vertical: 2.0'), findsOneWidget);
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
      expect(find.textContaining('Sin superficie 3D disponible.'), findsOneWidget);
    });

    testWidgets('muestra un mensaje cuando la superficie es track', (tester) async {
      await pumpView(
        tester,
        TerrainSurface(
          kind: TerrainSurfaceKind.track,
          vertices: const [],
          triangles: const [],
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Sin superficie 3D disponible para este track.'), findsOneWidget);
    });

    testWidgets('muestra el aviso de precisión y la exageración en la vista valida',
        (tester) async {
      final points = buildPolygonPoints();
      final surface = polygonSurface(points);

      await pumpView(tester, surface);

      expect(
        find.text(
          'Representación aproximada: la altitud del GPS tiene menor precisión que la horizontal',
        ),
        findsOneWidget,
      );
    });
  });
}
