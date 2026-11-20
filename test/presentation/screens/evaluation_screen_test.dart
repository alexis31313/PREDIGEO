import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:predigeo/domain/entities/measurement.dart';
import 'package:predigeo/domain/repositories/measurement_repository.dart';
import 'package:predigeo/presentation/providers/measurement_repository_provider.dart';
import 'package:predigeo/presentation/screens/evaluation_screen.dart';

import '../../support/fixtures.dart';

class _MockRepository extends Mock implements MeasurementRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(buildMeasurement());
  });

  late _MockRepository repository;

  setUp(() {
    repository = _MockRepository();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          measurementRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: EvaluationScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('muestra las evaluaciones de las mediciones guardadas',
      (tester) async {
    when(() => repository.getAll()).thenAnswer(
          (_) async => [buildMeasurement(id: 1, evaluations: [buildEvaluation(measurementId: 1)])],
        );
    when(() => repository.getEvaluations(1))
        .thenAnswer((_) async => [buildEvaluation(measurementId: 1)]);

    await pumpScreen(tester);

    expect(find.text('Evaluación'), findsOneWidget);
    expect(find.text('Lote de prueba'), findsOneWidget);
  });

  testWidgets('muestra el estado vacío cuando no hay mediciones', (tester) async {
    when(() => repository.getAll()).thenAnswer((_) async => <Measurement>[]);

    await pumpScreen(tester);

    expect(find.text('Aún no hay datos para evaluar.'), findsOneWidget);
  });
}
