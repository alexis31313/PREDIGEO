import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias del mapa persistidas en el dispositivo.
///
/// Guarda si el usuario prefiere la vista satelital o la normal, de forma que
/// la elección se conserve entre sesiones. Se aísla detrás de una clase para
/// poder simularla en las pruebas.
class MapPreferencesService {
  static const String _satelliteKey = 'maps.map_style_satellite';

  const MapPreferencesService();

  /// `true` si el usuario prefiere la vista satelital.
  Future<bool> isSatellite() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_satelliteKey) ?? false;
  }

  /// Persiste la preferencia de vista del mapa.
  Future<void> setSatellite(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_satelliteKey, value);
  }
}
