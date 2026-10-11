// Proveedor del estilo de mapa (normal o satelital) con persistencia local.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/map_preferences_service.dart';

/// Servicio de preferencias del mapa. Se puede sobrescribir en pruebas.
final mapPreferencesServiceProvider = Provider<MapPreferencesService>((ref) {
  return const MapPreferencesService();
});

/// Controla si el mapa se muestra en modo satelital.
///
/// Carga la preferencia guardada de forma asíncrona y la persiste en cada
/// cambio. Mientras carga, el estado inicial es la vista normal.
class MapStyleNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadPreference();
    return false;
  }

  Future<void> _loadPreference() async {
    final stored = await ref.read(mapPreferencesServiceProvider).isSatellite();
    if (stored != state) state = stored;
  }

  /// Cambia explícitamente la vista del mapa.
  Future<void> setSatellite(bool value) async {
    state = value;
    await ref.read(mapPreferencesServiceProvider).setSatellite(value);
  }

  /// Alterna entre vista normal y satelital.
  Future<void> toggle() => setSatellite(!state);
}

final mapStyleProvider = NotifierProvider<MapStyleNotifier, bool>(
  MapStyleNotifier.new,
);
