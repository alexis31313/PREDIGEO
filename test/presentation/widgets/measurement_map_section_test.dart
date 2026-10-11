import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:predigeo/domain/entities/geo_point.dart';
import 'package:predigeo/presentation/providers/connectivity_provider.dart';
import 'package:predigeo/presentation/widgets/measurement_map_section.dart';
import 'package:predigeo/presentation/widgets/terrain_relief_view.dart';

import '../../support/fixtures.dart';

void main() {
  Future<void> pumpSection(
    WidgetTester tester, {
    required bool online,
    Widget Function(List<GeoPoint> points, bool closePolygon)? mapBuilder,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isOnlineProvider.overrideWithValue(online),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 420,
                child: MeasurementMapSection(
                  points: buildPolygonPoints(),
                  mapBuilder: mapBuilder,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sin conexión muestra la vista de relieve local', (tester) async {
    await pumpSection(tester, online: false);

    expect(find.byType(TerrainReliefView), findsOneWidget);
    expect(find.text('Vista de relieve (sin conexión)'), findsOneWidget);
  });

  testWidgets('con conexión delega en el mapa', (tester) async {
    await pumpSection(
      tester,
      online: true,
      mapBuilder: (points, closePolygon) =>
          const SizedBox(key: Key('fake-map')),
    );

    expect(find.byKey(const Key('fake-map')), findsOneWidget);
    expect(find.byType(TerrainReliefView), findsNothing);
  });
}
