// Persistencia de los puntos interiores (muestreo 3D) de cada medición.
//
// Se guardan en SharedPreferences como JSON, una clave por medición, para no
// modificar el esquema SQLite. La clase está aislada para poder migrarla a
// SQLite más adelante sin cambiar el resto de la aplicación.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/geo_point.dart';

class InteriorPointsStore {
  static const String keyPrefix = 'interior_points_v1_';

  final Future<SharedPreferences> Function() _prefs;

  InteriorPointsStore({Future<SharedPreferences> Function()? prefs})
      : _prefs = prefs ?? SharedPreferences.getInstance;

  static String keyFor(int measurementId) => '$keyPrefix$measurementId';

  /// Guarda (o reemplaza) los puntos interiores de una medición. Una lista
  /// vacía borra la entrada.
  Future<void> save(int measurementId, List<GeoPoint> points) async {
    final prefs = await _prefs();
    if (points.isEmpty) {
      await prefs.remove(keyFor(measurementId));
      return;
    }
    final encoded = jsonEncode(<Map<String, Object>>[
      for (final p in points)
        <String, Object>{
          'seq': p.seq,
          'lat': p.latitude,
          'lon': p.longitude,
          'alt': p.altitude,
          'acc': p.accuracy,
          'ts': p.timestamp.toIso8601String(),
        },
    ]);
    await prefs.setString(keyFor(measurementId), encoded);
  }

  /// Puntos interiores de una medición (lista vacía si no hay o si los datos
  /// guardados están dañados).
  Future<List<GeoPoint>> load(int measurementId) async {
    final prefs = await _prefs();
    final raw = prefs.getString(keyFor(measurementId));
    if (raw == null || raw.isEmpty) return const <GeoPoint>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <GeoPoint>[];
      final result = <GeoPoint>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final lat = (item['lat'] as num?)?.toDouble();
        final lon = (item['lon'] as num?)?.toDouble();
        if (lat == null || lon == null) continue;
        result.add(
          GeoPoint(
            measurementId: measurementId,
            seq: (item['seq'] as num?)?.toInt() ?? result.length,
            latitude: lat,
            longitude: lon,
            altitude: (item['alt'] as num?)?.toDouble() ?? double.nan,
            accuracy: (item['acc'] as num?)?.toDouble() ?? 0,
            timestamp: DateTime.tryParse('${item['ts']}') ?? DateTime(1970),
          ),
        );
      }
      return result;
    } catch (_) {
      return const <GeoPoint>[];
    }
  }

  /// Borra los puntos interiores de una medición.
  Future<void> delete(int measurementId) async {
    final prefs = await _prefs();
    await prefs.remove(keyFor(measurementId));
  }

  /// Borra los puntos interiores de todas las mediciones.
  Future<void> deleteAll() async {
    final prefs = await _prefs();
    final keys =
        prefs.getKeys().where((k) => k.startsWith(keyPrefix)).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
