import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
              width: 340,
              height: 420,
              child: TerrainReliefToggleView(points: buildPolygonPoints()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> open3D(WidgetTester tester) async {
    await tester.tap(find.text('3D'));
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
      await open3D(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(TerrainRelief3DView), findsOneWidget);
      expect(find.text('Exageración: Auto'), findsOneWidget);
    });

    testWidgets('el control de exageración cambia el factor mostrado',
        (tester) async {
      await pumpView(tester);
      await open3D(tester);

      await tester.tap(find.text('Exageración: Auto'));
      await tester.pumpAndSettle();
      await tester
          .tap(find.widgetWithText(CheckedPopupMenuItem<double>, '5x'));
      await tester.pumpAndSettle();

      expect(find.text('Exageración: 5x'), findsOneWidget);
      expect(find.text('Exageración vertical: 5.0x'), findsOneWidget);
    });

    testWidgets('las opciones de malla, curvas y suavizado se activan',
        (tester) async {
      await pumpView(tester);
      await open3D(tester);

      for (final label in ['Malla', 'Curvas', 'Suavizar']) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }

      expect(tester.takeException(), isNull);
      final chips = tester.widgetList<FilterChip>(find.byType(FilterChip));
      expect(chips.every((chip) => chip.selected), isTrue);
    });

    testWidgets('muestra el aviso de precisión en modo 2D', (tester) async {
      await pumpView(tester);

      expect(find.text(terrainAccuracyDisclaimer), findsOneWidget);
    });

    testWidgets('muestra el aviso de precisión en modo 3D', (tester) async {
      await pumpView(tester);
      await open3D(tester);

      expect(find.text(terrainAccuracyDisclaimer), findsOneWidget);
    });

    testWidgets('abre el relieve 3D en pantalla completa', (tester) async {
      await pumpView(tester);

      await tester.tap(find.byTooltip('Ver relieve 3D en pantalla completa'));
      await tester.pumpAndSettle();

      expect(find.byType(TerrainRelief3DScreen), findsOneWidget);
      expect(find.text('Relieve 3D'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(TerrainRelief3DScreen),
          matching: find.byType(TerrainRelief3DView),
        ),
        findsOneWidget,
      );
    });
  });
}
