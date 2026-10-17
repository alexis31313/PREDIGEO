import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:predigeo/domain/entities/geo_point.dart';
import 'package:predigeo/domain/entities/measurement.dart';
import 'package:predigeo/domain/entities/measurement_enums.dart';
import 'package:predigeo/domain/repositories/measurement_repository.dart';
import 'package:predigeo/presentation/providers/measurement_repository_provider.dart';
import 'package:predigeo/presentation/screens/measurement_detail_screen.dart';

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

  final sampleMeasurement = Measurement(
    id: 1,
    name: 'Terreno La Esperanza',
    type: MeasurementType.area,
    areaM2: 1250.5,
    perimeterM: 145.2,
    mode: MeasurementMode.online,
    category: MeasurementCategory.ruralOpen,
    notes: 'Medición de prueba',
    createdAt: DateTime(2024, 1, 15, 10, 0),
    points: samplePoints,
  );

  setUpAll(() {
    registerFallbackValue(sampleMeasurement);
  });

  setUp(() {
    mockRepository = MockMeasurementRepository();
  });

  Widget createTestWidget({Measurement? measurement}) {
    return ProviderScope(
      overrides: [
        measurementRepositoryProvider.overrideWithValue(mockRepository),
        measurementDetailProvider(measurement?.id ?? sampleMeasurement.id!)
            .overrideWith((ref) => measurement ?? sampleMeasurement),
      ],
      child: MaterialApp(
        home: MeasurementDetailScreen(
          measurementId: measurement?.id ?? sampleMeasurement.id!,
        ),
      ),
    );
  }

  group('MeasurementDetailScreen', () {
    testWidgets('Test detail screen shows measurement info', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Terreno La Esperanza'), findsWidgets);
      // El área se muestra en la unidad preferida (ha por defecto): 1250.5 m² ≈ 0.13 ha.
      expect(find.textContaining('ha'), findsWidgets);
      expect(find.textContaining('145.2'), findsWidgets);
    });

    testWidgets('Test rename dialog opens and saves', (tester) async {
      when(() => mockRepository.update(any()))
          .thenAnswer((_) async => sampleMeasurement.copyWith(name: 'Nuevo Nombre'));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);

      await tester.enterText(find.byType(TextField).first, 'Nuevo Nombre');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      verify(() => mockRepository.update(any())).called(1);
    });

    testWidgets('Test delete shows confirmation dialog', (tester) async {
      when(() => mockRepository.delete(any())).thenAnswer((_) async {});

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('Test delete shows Snackbar with undo', (tester) async {
      when(() => mockRepository.delete(any())).thenAnswer((_) async {});

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Eliminar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('Test duplicate creates copy', (tester) async {
      when(() => mockRepository.insertMeasurement(any()))
          .thenAnswer((_) async => sampleMeasurement.copyWith(id: 2));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.copy));
      await tester.pumpAndSettle();

      verify(() => mockRepository.insertMeasurement(any())).called(1);
    });
  });
}
