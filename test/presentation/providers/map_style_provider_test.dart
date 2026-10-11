import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:predigeo/presentation/providers/map_style_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  MapStyleNotifier notifier(ProviderContainer container) =>
      container.read(mapStyleProvider.notifier);

  test('por defecto la vista es normal', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(mapStyleProvider), isFalse);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(mapStyleProvider), isFalse);
  });

  test('carga la preferencia satelital guardada', () async {
    SharedPreferences.setMockInitialValues({
      'maps.map_style_satellite': true,
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(mapStyleProvider.notifier);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(container.read(mapStyleProvider), isTrue);
  });

  test('setSatellite actualiza el estado y persiste', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await notifier(container).setSatellite(true);
    expect(container.read(mapStyleProvider), isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('maps.map_style_satellite'), isTrue);
  });

  test('toggle alterna entre vista normal y satelital', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await notifier(container).toggle();
    expect(container.read(mapStyleProvider), isTrue);

    await notifier(container).toggle();
    expect(container.read(mapStyleProvider), isFalse);
  });
}
