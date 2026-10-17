// Proveedor de ajustes de PrediGeo con persistencia local.
// Gestiona el modo de operación, muestras por punto, umbral de precisión,
// unidad de área preferida, tema y banderas del flujo de primer uso.
// Toda la persistencia es 100 % offline mediante shared_preferences.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/measurement_enums.dart';
import '../../domain/usecases/geo/area_units.dart';
import '../../domain/usecases/signal_processing/outlier_filter.dart';
import '../../domain/usecases/signal_processing/point_capture_service.dart';
import '../../domain/usecases/signal_processing/weighted_averager.dart';
import 'gps_state_notifier.dart';

/// Claves de persistencia en [SharedPreferences].
class AppSettingsKeys {
  AppSettingsKeys._();

  static const String operationMode = 'predigeo.operation_mode';
  static const String samplesPerPoint = 'predigeo.samples_per_point';
  static const String gpsAccuracyThreshold = 'predigeo.gps_accuracy_threshold';
  static const String areaUnit = 'predigeo.area_unit';
  static const String themeMode = 'predigeo.theme_mode';
  static const String onboardingCompleted = 'predigeo.onboarding_completed';
  static const String consentAccepted = 'predigeo.consent_accepted';
  static const String consentDate = 'predigeo.consent_date';
  static const String permissionCompleted = 'predigeo.permission_completed';
}

/// Unidad de área preferida para mostrar resultados.
enum AreaUnitPref {
  squareMeters('m2', 'Metros cuadrados (m²)'),
  hectares('ha', 'Hectáreas (ha)'),
  fanegadas('fanegada', 'Fanegadas');

  const AreaUnitPref(this.value, this.label);

  final String value;
  final String label;

  static AreaUnitPref fromValue(String? value) {
    for (final unit in AreaUnitPref.values) {
      if (unit.value == value) return unit;
    }
    return AreaUnitPref.hectares;
  }
}

/// Estado inmutable de los ajustes de la aplicación.
@immutable
class SettingsState {
  final MeasurementMode operationMode;
  final int samplesPerPoint;
  final double gpsAccuracyThreshold;
  final AreaUnitPref areaUnit;
  final ThemeMode themeMode;
  final bool onboardingCompleted;
  final bool consentAccepted;
  final DateTime? consentDate;
  final bool permissionCompleted;

  const SettingsState({
    this.operationMode = MeasurementMode.offline,
    this.samplesPerPoint = 10,
    this.gpsAccuracyThreshold = 20.0,
    this.areaUnit = AreaUnitPref.hectares,
    this.themeMode = ThemeMode.system,
    this.onboardingCompleted = false,
    this.consentAccepted = false,
    this.consentDate,
    this.permissionCompleted = false,
  });

  SettingsState copyWith({
    MeasurementMode? operationMode,
    int? samplesPerPoint,
    double? gpsAccuracyThreshold,
    AreaUnitPref? areaUnit,
    ThemeMode? themeMode,
    bool? onboardingCompleted,
    bool? consentAccepted,
    DateTime? consentDate,
    bool clearConsentDate = false,
    bool? permissionCompleted,
  }) {
    return SettingsState(
      operationMode: operationMode ?? this.operationMode,
      samplesPerPoint: samplesPerPoint ?? this.samplesPerPoint,
      gpsAccuracyThreshold: gpsAccuracyThreshold ?? this.gpsAccuracyThreshold,
      areaUnit: areaUnit ?? this.areaUnit,
      themeMode: themeMode ?? this.themeMode,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      consentAccepted: consentAccepted ?? this.consentAccepted,
      consentDate:
          clearConsentDate ? null : (consentDate ?? this.consentDate),
      permissionCompleted: permissionCompleted ?? this.permissionCompleted,
    );
  }

  /// Formatea un área en m² usando la unidad preferida.
  String formatArea(double m2) {
    return AreaUnits.formatAreaWithUnit(m2, areaUnit.value);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SettingsState &&
        other.operationMode == operationMode &&
        other.samplesPerPoint == samplesPerPoint &&
        other.gpsAccuracyThreshold == gpsAccuracyThreshold &&
        other.areaUnit == areaUnit &&
        other.themeMode == themeMode &&
        other.onboardingCompleted == onboardingCompleted &&
        other.consentAccepted == consentAccepted &&
        other.consentDate == consentDate &&
        other.permissionCompleted == permissionCompleted;
  }

  @override
  int get hashCode => Object.hash(
        operationMode,
        samplesPerPoint,
        gpsAccuracyThreshold,
        areaUnit,
        themeMode,
        onboardingCompleted,
        consentAccepted,
        consentDate,
        permissionCompleted,
      );
}

/// Notificador de ajustes con persistencia en [SharedPreferences].
///
/// Lee los valores guardados al construirse y persiste cada cambio de forma
/// inmediata. Todo funciona sin conexión.
class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    // Estado inicial con valores por defecto; la carga real es asíncrona.
    Future.microtask(_loadFromPreferences);
    return const SettingsState();
  }

  /// Carga los valores persistidos y actualiza el estado.
  Future<void> _loadFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final modeValue = prefs.getString(AppSettingsKeys.operationMode);
    final themeValue = prefs.getString(AppSettingsKeys.themeMode);
    final areaValue = prefs.getString(AppSettingsKeys.areaUnit);
    final consentDateStr = prefs.getString(AppSettingsKeys.consentDate);

    state = SettingsState(
      operationMode:
          MeasurementMode.fromValue(modeValue) ?? MeasurementMode.offline,
      samplesPerPoint: _clampSamples(
        prefs.getInt(AppSettingsKeys.samplesPerPoint) ?? 10,
      ),
      gpsAccuracyThreshold:
          prefs.getDouble(AppSettingsKeys.gpsAccuracyThreshold) ?? 20.0,
      areaUnit: AreaUnitPref.fromValue(areaValue),
      themeMode: _themeModeFromString(themeValue),
      onboardingCompleted:
          prefs.getBool(AppSettingsKeys.onboardingCompleted) ?? false,
      consentAccepted: prefs.getBool(AppSettingsKeys.consentAccepted) ?? false,
      consentDate:
          consentDateStr == null ? null : DateTime.tryParse(consentDateStr),
      permissionCompleted:
          prefs.getBool(AppSettingsKeys.permissionCompleted) ?? false,
    );
  }

  /// Recarga los ajustes desde disco (útil tras cambios externos).
  Future<void> reload() => _loadFromPreferences();

  Future<void> setOperationMode(MeasurementMode mode) async {
    state = state.copyWith(operationMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppSettingsKeys.operationMode, mode.value);
  }

  Future<void> setSamplesPerPoint(int samples) async {
    final clamped = _clampSamples(samples);
    state = state.copyWith(samplesPerPoint: clamped);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppSettingsKeys.samplesPerPoint, clamped);
  }

  Future<void> setGpsAccuracyThreshold(double threshold) async {
    final clamped = threshold.clamp(3.0, 50.0).toDouble();
    state = state.copyWith(gpsAccuracyThreshold: clamped);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppSettingsKeys.gpsAccuracyThreshold, clamped);
  }

  Future<void> setAreaUnit(AreaUnitPref unit) async {
    state = state.copyWith(areaUnit: unit);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppSettingsKeys.areaUnit, unit.value);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppSettingsKeys.themeMode, _themeModeToString(mode));
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(onboardingCompleted: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppSettingsKeys.onboardingCompleted, true);
  }

  Future<void> acceptConsent() async {
    final now = DateTime.now();
    state = state.copyWith(consentAccepted: true, consentDate: now);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppSettingsKeys.consentAccepted, true);
    await prefs.setString(
      AppSettingsKeys.consentDate,
      now.toIso8601String(),
    );
  }

  Future<void> completePermissionStep() async {
    state = state.copyWith(permissionCompleted: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppSettingsKeys.permissionCompleted, true);
  }

  Future<void> resetToDefaults() async {
    state = const SettingsState(
      onboardingCompleted: true,
      consentAccepted: true,
      permissionCompleted: true,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppSettingsKeys.operationMode,
      MeasurementMode.offline.value,
    );
    await prefs.setInt(AppSettingsKeys.samplesPerPoint, 10);
    await prefs.setDouble(AppSettingsKeys.gpsAccuracyThreshold, 20.0);
    await prefs.setString(AppSettingsKeys.areaUnit, AreaUnitPref.hectares.value);
    await prefs.setString(AppSettingsKeys.themeMode, 'system');
  }

  /// Restablece también las banderas de primer uso (para pruebas).
  Future<void> resetFirstRun() async {
    state = const SettingsState();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppSettingsKeys.onboardingCompleted, false);
    await prefs.setBool(AppSettingsKeys.consentAccepted, false);
    await prefs.remove(AppSettingsKeys.consentDate);
    await prefs.setBool(AppSettingsKeys.permissionCompleted, false);
  }

  static int _clampSamples(int value) => value.clamp(5, 30);

  static ThemeMode _themeModeFromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}

/// Proveedor principal de ajustes.
final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

/// Estado agregado del arranque: decide la siguiente pantalla del flujo.
@immutable
class StartupState {
  final bool showOnboarding;
  final bool showConsent;
  final bool showPermission;
  final bool ready;

  const StartupState({
    required this.showOnboarding,
    required this.showConsent,
    required this.showPermission,
    required this.ready,
  });

  /// Ruta inicial que debe mostrar el router.
  String get initialRoute {
    if (showOnboarding) return '/onboarding';
    if (showConsent) return '/consent';
    if (showPermission) return '/permission';
    return '/';
  }
}

/// Deriva el estado de arranque desde los ajustes persistidos.
final startupStateProvider = Provider<StartupState>((ref) {
  final settings = ref.watch(settingsProvider);
  final showOnboarding = !settings.onboardingCompleted;
  final showConsent =
      settings.onboardingCompleted && !settings.consentAccepted;
  final showPermission = settings.onboardingCompleted &&
      settings.consentAccepted &&
      !settings.permissionCompleted;
  return StartupState(
    showOnboarding: showOnboarding,
    showConsent: showConsent,
    showPermission: showPermission,
    ready: !showOnboarding && !showConsent && !showPermission,
  );
});

/// Servicio de captura configurado con los ajustes actuales.
///
/// Usa el número de muestras y el umbral de precisión configurados por el
/// usuario. El umbral alimenta el [OutlierFilter]; el número de muestras se
/// expone para que la UI lo pase a [PointCaptureService.capturePoint].
final configuredCaptureServiceProvider =
    Provider<PointCaptureService>((ref) {
  final settings = ref.watch(settingsProvider);
  final locationService = ref.watch(locationServiceProvider);
  return PointCaptureService(
    locationService: locationService,
    outlierFilter: OutlierFilter(
      maxAccuracy: settings.gpsAccuracyThreshold,
    ),
    weightedAverager: const WeightedAverager(),
  );
});

/// Número de muestras configurado para [PointCaptureService.capturePoint].
final captureSamplesProvider = Provider<int>((ref) {
  return ref.watch(settingsProvider.select((s) => s.samplesPerPoint));
});

/// Umbral de precisión configurado (metros).
final captureAccuracyThresholdProvider = Provider<double>((ref) {
  return ref.watch(settingsProvider.select((s) => s.gpsAccuracyThreshold));
});

/// Formatea un área en m² con la unidad preferida del usuario.
final formattedAreaProvider =
    Provider.family<String, double>((ref, m2) {
  final settings = ref.watch(settingsProvider);
  return settings.formatArea(m2);
});
