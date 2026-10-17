// Pruebas del flujo de primer arranque y de los ajustes de PrediGeo.
// Verifica la redirección por StartupState, el bloqueo del consentimiento
// hasta aceptar y la persistencia de ajustes tras reiniciar el provider.
// Todo es offline: usa SharedPreferences con valores iniciales simulados.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:predigeo/domain/entities/measurement_enums.dart';
import 'package:predigeo/presentation/providers/settings_provider.dart';
import 'package:predigeo/presentation/screens/consent_screen.dart';
import 'package:predigeo/presentation/screens/onboarding_screen.dart';
import 'package:predigeo/presentation/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  /// Crea un contenedor y espera a que termine la carga inicial desde disco.
  Future<ProviderContainer> createLoadedContainer() async {
    final container = ProviderContainer();
    await container.read(settingsProvider.notifier).reload();
    return container;
  }

  group('Flujo completo de primer arranque', () {
    test('estado inicial lleva a onboarding', () async {
      final container = await createLoadedContainer();
      addTearDown(container.dispose);

      final startup = container.read(startupStateProvider);
      expect(startup.showOnboarding, isTrue);
      expect(startup.initialRoute, '/onboarding');
    });

    test('tras completar onboarding pide consentimiento', () async {
      final container = await createLoadedContainer();
      addTearDown(container.dispose);

      await container.read(settingsProvider.notifier).completeOnboarding();

      final startup = container.read(startupStateProvider);
      expect(startup.showOnboarding, isFalse);
      expect(startup.showConsent, isTrue);
      expect(startup.initialRoute, '/consent');
    });

    test('tras aceptar consentimiento pide permisos y luego Home',
        () async {
      final container = await createLoadedContainer();
      addTearDown(container.dispose);

      await container.read(settingsProvider.notifier).completeOnboarding();
      await container.read(settingsProvider.notifier).acceptConsent();

      var startup = container.read(startupStateProvider);
      expect(startup.showPermission, isTrue);
      expect(startup.initialRoute, '/permission');

      await container
          .read(settingsProvider.notifier)
          .completePermissionStep();

      startup = container.read(startupStateProvider);
      expect(startup.ready, isTrue);
      expect(startup.initialRoute, '/');
    });
  });

  group('Consentimiento bloquea el avance hasta aceptarse', () {
    testWidgets('botón Continuar deshabilitado hasta aceptar', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: ConsentScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final continueButton = find.widgetWithText(FilledButton, 'Continuar');
      expect(continueButton, findsOneWidget);
      expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();

      expect(
        tester.widget<FilledButton>(continueButton).onPressed,
        isNotNull,
      );
    });
  });

  group('Onboarding muestra 3 páginas y botón Omitir', () {
    testWidgets('PageView con 3 páginas e indicadores', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: OnboardingScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('¿Qué hace PrediGeo?'), findsOneWidget);
      expect(find.text('Omitir'), findsOneWidget);
      expect(find.text('Siguiente'), findsOneWidget);
    });
  });

  group('Ajustes persisten tras reiniciar el provider', () {
    test('cambio de muestras persiste', () async {
      final first = await createLoadedContainer();
      await first.read(settingsProvider.notifier).setSamplesPerPoint(25);
      expect(first.read(settingsProvider).samplesPerPoint, 25);
      first.dispose();

      final second = await createLoadedContainer();
      addTearDown(second.dispose);
      expect(second.read(settingsProvider).samplesPerPoint, 25);
    });

    test('cambio de unidad y modo persiste', () async {
      final first = await createLoadedContainer();
      await first
          .read(settingsProvider.notifier)
          .setAreaUnit(AreaUnitPref.fanegadas);
      await first
          .read(settingsProvider.notifier)
          .setOperationMode(MeasurementMode.online);
      first.dispose();

      final second = await createLoadedContainer();
      addTearDown(second.dispose);

      expect(
        second.read(settingsProvider).areaUnit,
        AreaUnitPref.fanegadas,
      );
      expect(
        second.read(settingsProvider).operationMode,
        MeasurementMode.online,
      );
    });

    testWidgets('SettingsScreen muestra las opciones', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ajustes'), findsOneWidget);
      expect(find.text('Modo de operación'), findsOneWidget);
      expect(find.text('Muestras por punto'), findsOneWidget);
      expect(find.text('Umbral de precisión GPS'), findsOneWidget);
      expect(find.text('Unidad de área preferida'), findsOneWidget);
      expect(find.text('Tema'), findsOneWidget);
      // La sección "Acerca de" está al final del ListView: desplazar.
      await tester.scrollUntilVisible(
        find.text('Acerca de'),
        500,
      );
      expect(find.text('Acerca de'), findsOneWidget);
    });
  });
}
