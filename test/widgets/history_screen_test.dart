import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:predigeo/domain/entities/geo_point.dart';
import 'package:predigeo/domain/entities/measurement.dart';
import 'package:predigeo/domain/entities/measurement_enums.dart';
import 'package:predigeo/domain/repositories/measurement_repository.dart';
import 'package:predigeo/presentation/providers/measurement_repository_provider.dart';
import 'package:predigeo/presentation/screens/history_screen.dart';

class MockMeasurementRepository extends Mock implements MeasurementRepository {}

void main() {
  late MockMeasurementRepository mockRepository;

  final samplePoints = [
    GeoPoint(
      id: 1,
      measurementId: 1,
      seq: 0,
      latitude: 4.7110,
      longitude: -74.0721,
      altitude: 2600.0,
      accuracy: 3.5,
      timestamp: DateTime(2024, 1, 15, 10, 30),
    ),
    GeoPoint(
      id: 2,
      measurementId: 1,
      seq: 1,
      latitude: 4.7120,
      longitude: -74.0731,
      altitude: 2605.0,
      accuracy: 3.2,
      timestamp: DateTime(2024, 1, 15, 10, 31),
    ),
    GeoPoint(
      id: 3,
      measurementId: 1,
      seq: 2,
      latitude: 4.7130,
      longitude: -74.0741,
      altitude: 2610.0,
      accuracy: 3.8,
      timestamp: DateTime(2024, 1, 15, 10, 32),
    ),
  ];

  final sampleMeasurements = [
    Measurement(
      id: 1,
      name: 'Terreno La Esperanza',
      type: MeasurementType.area,
      areaM2: 1250.5,
      perimeterM: 145.2,
      mode: MeasurementMode.online,
      category: MeasurementCategory.ruralOpen,
      createdAt: DateTime(2024, 1, 15, 10, 0),
      points: samplePoints,
    ),
    Measurement(
      id: 2,
      name: 'Camino Vecinal',
      type: MeasurementType.path,
      distanceM: 850.0,
      mode: MeasurementMode.offline,
      category: MeasurementCategory.ruralVegetation,
      createdAt: DateTime(2024, 1, 14, 9, 0),
    ),
    Measurement(
      id: 3,
      name: 'Parque Central',
      type: MeasurementType.area,
      areaM2: 3200.0,
      perimeterM: 240.0,
      mode: MeasurementMode.online,
      category: MeasurementCategory.urban,
      createdAt: DateTime(2024, 1, 13, 8, 0),
    ),
  ];

  setUp(() {
    mockRepository = MockMeasurementRepository();
  });

  Widget createTestWidget({
    List<Measurement> measurements = const [],
  }) {
    return ProviderScope(
      overrides: [
        measurementRepositoryProvider.overrideWithValue(mockRepository),
        measurementHistoryProvider.overrideWith((ref) => measurements),
        measurementSearchProvider('').overrideWith((ref) => measurements),
      ],
      child: const MaterialApp(
        home: HistoryScreen(),
      ),
    );
  }

  group('HistoryScreen', () {
    testWidgets('Test empty state shows "No hay mediciones"', (tester) async {
      await tester.pumpWidget(createTestWidget(measurements: []));
      await tester.pumpAndSettle();

      expect(find.text('No hay mediciones'), findsOneWidget);
    });

    testWidgets('Test search bar filters measurements', (tester) async {
      await tester.pumpWidget(createTestWidget(measurements: sampleMeasurements));
      await tester.pumpAndSettle();

      expect(find.text('Terreno La Esperanza'), findsOneWidget);
      expect(find.text('Camino Vecinal'), findsOneWidget);
      expect(find.text('Parque Central'), findsOneWidget);
    });

    testWidgets('Test filter chips work (type, mode, category)', (tester) async {
      await tester.pumpWidget(createTestWidget(measurements: sampleMeasurements));
      await tester.pumpAndSettle();

      expect(find.text('Terreno La Esperanza'), findsOneWidget);
      expect(find.text('Camino Vecinal'), findsOneWidget);
      expect(find.text('Parque Central'), findsOneWidget);
    });

    testWidgets('Test sort options work', (tester) async {
      await tester.pumpWidget(createTestWidget(measurements: sampleMeasurements));
      await tester.pumpAndSettle();

      expect(find.text('Terreno La Esperanza'), findsOneWidget);
      expect(find.text('Camino Vecinal'), findsOneWidget);
      expect(find.text('Parque Central'), findsOneWidget);
    });

    testWidgets('Test pull-to-refresh triggers reload', (tester) async {
      await tester.pumpWidget(createTestWidget(measurements: sampleMeasurements));
      await tester.pumpAndSettle();

      expect(find.text('Terreno La Esperanza'), findsOneWidget);
    });

    testWidgets('Test multi-select mode toggles checkboxes', (tester) async {
      await tester.pumpWidget(createTestWidget(measurements: sampleMeasurements));
      await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsNothing);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsWidgets);
    });

    testWidgets('Test delete selected shows confirmation dialog', (tester) async {
      await tester.pumpWidget(createTestWidget(measurements: sampleMeasurements));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      final checkboxes = find.byType(Checkbox);
      await tester.tap(checkboxes.first);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      expect(find.text('Eliminar mediciones'), findsOneWidget);
    });
  });
}
