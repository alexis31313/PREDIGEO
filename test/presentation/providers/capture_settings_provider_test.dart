import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:predigeo/presentation/providers/capture_settings_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() => container.dispose());

  CaptureSettingsNotifier notifier() =>
      container.read(captureSettingsProvider.notifier);

  CaptureSettings settings() => container.read(captureSettingsProvider);

  test('valores por defecto', () {
    expect(settings().samplesPerPoint, 10);
    expect(settings().maxAccuracyM, 20.0);
    expect(settings().timeout, const Duration(seconds: 30));
  });

  test('setSamplesPerPoint actualiza el valor', () {
    notifier().setSamplesPerPoint(5);
    expect(settings().samplesPerPoint, 5);
  });

  test('setSamplesPerPoint ignora valores no positivos', () {
    notifier().setSamplesPerPoint(0);
    notifier().setSamplesPerPoint(-3);
    expect(settings().samplesPerPoint, 10);
  });

  test('setMaxAccuracyM actualiza el valor', () {
    notifier().setMaxAccuracyM(10.0);
    expect(settings().maxAccuracyM, 10.0);
  });

  test('setMaxAccuracyM ignora valores no positivos', () {
    notifier().setMaxAccuracyM(0);
    expect(settings().maxAccuracyM, 20.0);
  });

  test('reset vuelve a los valores por defecto', () {
    notifier().setSamplesPerPoint(3);
    notifier().setMaxAccuracyM(5);
    notifier().reset();

    expect(settings(), const CaptureSettings());
  });
}
