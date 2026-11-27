import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:predigeo/domain/usecases/signal_processing/captured_point.dart';
import 'package:predigeo/presentation/providers/measurement_session_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  MeasurementSessionNotifier notifier() =>
      container.read(measurementSessionProvider.notifier);
  MeasurementSessionState state() => container.read(measurementSessionProvider);

  CapturedPoint captured(
    double lat,
    double lon, {
    required double altitude,
    double? pressure,
  }) {
    return CapturedPoint(
      latitude: lat,
      longitude: lon,
      altitude: altitude,
      estimatedAccuracy: 4,
      sampleCount: 10,
      timestamp: DateTime(2026, 3, 15, 14, 30),
      pressureHpa: pressure,
    );
  }

  test('sin presión las altitudes son las del GPS', () {
    notifier().addCapturedPoint(captured(1.1538, -76.6510, altitude: 430));
    notifier().addCapturedPoint(captured(1.1539, -76.6510, altitude: 445));

    expect(state().usesBarometer, isFalse);
    expect(state().points.map((p) => p.altitude), [430, 445]);
  });

  test('con barómetro el relieve sigue la presión y no el ruido del GPS', () {
    // Relieve real: el segundo punto está ~2 m más alto, el interior ~4 m.
    notifier().addCapturedPoint(
        captured(1.1538, -76.6510, altitude: 438, pressure: 960.0));
    notifier().addCapturedPoint(
        captured(1.1539, -76.6510, altitude: 425, pressure: 960.0 - 0.226));
    notifier().addCapturedPoint(
        captured(1.1539, -76.6509, altitude: 431, pressure: 960.0));
    notifier().addInteriorPoint(
        captured(1.15385, -76.65095, altitude: 436, pressure: 960.0 - 0.452));

    final s = state();
    expect(s.usesBarometer, isTrue);
    final base = s.points[0].altitude;
    expect(s.points[1].altitude - base, closeTo(2, 0.3));
    expect(s.points[2].altitude - base, closeTo(0, 0.05));
    expect(s.interiorPoints[0].altitude - base, closeTo(4, 0.3));
  });

  test('quitar el último punto mantiene sincronizadas las listas', () {
    notifier().addCapturedPoint(
        captured(1.1538, -76.6510, altitude: 430, pressure: 960));
    notifier().addCapturedPoint(
        captured(1.1539, -76.6510, altitude: 431, pressure: 959.8));
    notifier().removeLastPoint();

    expect(state().points, hasLength(1));
    expect(state().pointPressures, hasLength(1));
    expect(state().pointGpsAltitudes, hasLength(1));
    expect(state().usesBarometer, isFalse);
    // Con un solo punto con presión vuelve a la altitud GPS original.
    expect(state().points.single.altitude, 430);
  });
}
