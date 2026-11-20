import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:predigeo/domain/usecases/geo/terrain_surface.dart';
import 'package:predigeo/presentation/widgets/terrain_relief_3d_view.dart';
import 'package:predigeo/presentation/widgets/terrain_relief_toggle_view.dart';
import 'package:predigeo/presentation/widgets/terrain_relief_view.dart';

import '../../support/fixtures.dart';

void main() {
  Future<void> pumpView(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              height: 260,
              child: TerrainReliefToggleView(points: buildPolygonPoints()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('TerrainReliefToggleView', () {
    testWidgets('muestra la vista 2D por defecto', (tester) async {
      await pumpView(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(TerrainReliefView), findsOneWidget);
      expect(find.byType(TerrainRelief3DView), findsNothing);
    });

    testWidgets('el toggle muestra la vista 3D al pulsar 3D', (tester) async {
      await pumpView(tester);

      await tester.tap(find.text('3D'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(TerrainRelief3DView), findsOneWidget);
      expect(find.text('Exageración vertical: 2.0'), findsOneWidget);
    });

    testWidgets('el control de exageración cambia el factor mostrado',
        (tester) async {
      await pumpView(tester);

      await tester.tap(find.text('3D'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('5x'));
      await tester.pumpAndSettle();

      expect(find.text('Exageración vertical: 5.0'), findsOneWidget);
    });

    testWidgets('muestra el aviso de precisión en modo 2D', (tester) async {
      await pumpView(tester);

      expect(
        find.text(
          'Representación aproximada: la altitud del GPS tiene menor precisión que la horizontal',
        ),
        findsOneWidget,
      );
    });

    testWidgets('muestra el aviso de precisión en modo 3D', (tester) async {
      await pumpView(tester);

      await tester.tap(find.text('3D'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Representación aproximada: la altitud del GPS tiene menor precisión que la horizontal',
        ),
        findsOneWidget,
      );
    });
  });
}
