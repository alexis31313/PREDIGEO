import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:predigeo/data/datasources/location_service.dart';
import 'package:predigeo/data/datasources/wake_lock_service.dart';
import 'package:predigeo/domain/entities/gps_reading.dart';
import 'package:predigeo/domain/repositories/measurement_repository.dart';
import 'package:predigeo/domain/usecases/signal_processing/captured_point.dart';
import 'package:predigeo/domain/usecases/signal_processing/point_capture_service.dart';
import 'package:predigeo/presentation/providers/capture_service_provider.dart';
import 'package:predigeo/presentation/providers/connectivity_provider.dart';
import 'package:predigeo/presentation/providers/gps_state_notifier.dart';
import 'package:predigeo/presentation/providers/measurement_repository_provider.dart';
import 'package:predigeo/presentation/screens/measure_screen.dart';

import '../../support/fixtures.dart';

class _MockLocationService extends Mock implements LocationService {}

class _MockRepository extends Mock implements MeasurementRepository {}

class _FakeCaptureService extends PointCaptureService {
  final double accuracy;

  _FakeCaptureService({this.accuracy = 3.0})
      : super(locationService: _MockLocationService());

  @override
  Future<CapturedPoint> capturePoint({
    int samples = 10,
    Duration timeout = const Duration(seconds: 30),
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(1.0);
    return CapturedPoint(
      latitude: 1.15380,
      longitude: -76.65100,
      altitude: 430.0,
      estimatedAccuracy: accuracy,
      sampleCount: samples,
      timestamp: DateTime(2026, 3, 15, 14, 30),
    );
  }
}

class _FakeWakeLock extends WakeLockService {
  const _FakeWakeLock();

  @override
  Future<void> enable() async {}

  @override
  Future<void> disable() async {}
}

void main() {
  setUpAll(() {
    registerFallbackValue(buildMeasurement());
  });

  late _MockLocationService locationService;
  late _MockRepository repository;

  final reading = GpsReading(
    latitude: 1.15380,
    longitude: -76.65100,
    altitude: 430.0,
    horizontalAccuracy: 4.0,
    altitudeAccuracy: 5.0,
    speed: 0.0,
    timestamp: DateTime(2026, 3, 15, 14, 30),
  );

  setUp(() {
    locationService = _MockLocationService();
    repository = _MockRepository();

    when(() => locationService.isServiceEnabled())
        .thenAnswer((_) async => true);
    when(() => locationService.checkPermission())
        .thenAnswer((_) async => 'granted');
    when(() => locationService.getCurrentReading())
        .thenAnswer((_) async => reading);
    when(() => locationService.getReadingStream())
        .thenAnswer((_) => Stream<GpsReading>.value(reading));
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    PointCaptureService? captureService,
  }) async {
    // Superficie amplia para que el ListView construya todos los hijos
    // (formulario incluido) sin depender del desplazamiento.
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationServiceProvider.overrideWithValue(locationService),
          measurementRepositoryProvider.overrideWithValue(repository),
          wakeLockServiceProvider.overrideWithValue(const _FakeWakeLock()),
          connectionStatusProvider
              .overrideWithValue(ConnectionStatus.disconnected),
          pointCaptureServiceProvider.overrideWithValue(
            captureService ?? _FakeCaptureService(),
          ),
        ],
        child: const MaterialApp(home: MeasureScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('muestra los controles principales y el banner offline',
      (tester) async {
    await pumpScreen(tester);

    expect(find.text('Nueva Medición'), findsOneWidget);
    expect(find.text('Modo Sin Conexión'), findsOneWidget);
    expect(find.text('Capturar punto'), findsOneWidget);
    expect(find.text('Guardar medición'), findsOneWidget);
    expect(find.text('Todavía no hay puntos capturados.'), findsOneWidget);
  });

  testWidgets('capturar tres puntos habilita el guardado', (tester) async {
    await pumpScreen(tester);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Capturar punto'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Puntos capturados'), findsOneWidget);

    // Sin nombre, el guardado sigue deshabilitado.
    var saveButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Guardar medición'),
    );
    expect(saveButton.onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, 'Lote de prueba');
    await tester.pumpAndSettle();

    saveButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Guardar medición'),
    );
    expect(saveButton.onPressed, isNotNull);
  });

  testWidgets('descarta un punto con precisión por encima del umbral',
      (tester) async {
    await pumpScreen(tester, captureService: _FakeCaptureService(accuracy: 50));

    await tester.tap(find.text('Capturar punto'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Punto descartado'), findsOneWidget);
    expect(find.text('Todavía no hay puntos capturados.'), findsOneWidget);
  });

  testWidgets('guardar persiste la medición en el repositorio', (tester) async {
    when(() => repository.insertMeasurement(any()))
        .thenAnswer((_) async => buildMeasurement(id: 1));
    await pumpScreen(tester);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Capturar punto'));
      await tester.pumpAndSettle();
    }

    await tester.enterText(find.byType(TextField).first, 'Lote de prueba');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guardar medición'));
    await tester.pumpAndSettle();

    verify(() => repository.insertMeasurement(any())).called(1);
    expect(find.text('Medición guardada localmente.'), findsOneWidget);
  });
}
