// Acceso al barómetro del dispositivo mediante canales de plataforma propios
// (implementados en MainActivity.kt), sin paquetes externos.

import 'dart:async';

import 'package:flutter/services.dart';

/// Lee la presión atmosférica (hPa) del sensor del dispositivo.
///
/// El barómetro mide diferencias de altura con una resolución de decímetros,
/// mucho mejor que la altitud del GPS (±5–15 m). Se usa solo para la altura
/// **relativa** entre los puntos de una misma sesión.
class BarometerService {
  static const MethodChannel _method =
      MethodChannel('predigeo/barometer/method');
  static const EventChannel _events =
      EventChannel('predigeo/barometer/events');

  bool? _available;

  /// `true` si el dispositivo tiene barómetro. Nunca lanza: en plataformas
  /// sin la implementación nativa (pruebas, escritorio) devuelve `false`.
  Future<bool> isAvailable() async {
    final cached = _available;
    if (cached != null) return cached;
    try {
      final result = await _method.invokeMethod<bool>('isAvailable');
      return _available = result ?? false;
    } catch (_) {
      return _available = false;
    }
  }

  /// Toma muestras de presión durante [duration] y devuelve la mediana en
  /// hPa, o `null` si no hay barómetro o no llegaron lecturas.
  Future<double?> samplePressure({
    Duration duration = const Duration(seconds: 3),
  }) async {
    if (!await isAvailable()) return null;
    final samples = <double>[];
    StreamSubscription<dynamic>? subscription;
    try {
      subscription = _events.receiveBroadcastStream().listen(
        (value) {
          if (value is num && value.isFinite && value > 0) {
            samples.add(value.toDouble());
          }
        },
        onError: (_) {},
        cancelOnError: false,
      );
      await Future<void>.delayed(duration);
    } catch (_) {
      return null;
    } finally {
      await subscription?.cancel();
    }
    if (samples.isEmpty) return null;
    samples.sort();
    final mid = samples.length ~/ 2;
    return samples.length.isOdd
        ? samples[mid]
        : (samples[mid - 1] + samples[mid]) / 2;
  }
}
