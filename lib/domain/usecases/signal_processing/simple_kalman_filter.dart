import 'dart:math';

import '../../entities/gps_reading.dart';

/// Filtro de Kalman bidimensional para coordenadas GPS (latitud, longitud).
/// Implementa las ecuaciones estándar de predicción y actualización.
class SimpleKalmanFilter2D {
  final double processNoise;

  double? _lat;
  double? _lon;
  double _p11;
  double _p12;
  double _p21;
  double _p22;
  bool _initialized;

  /// Crea un filtro de Kalman 2D.
  /// [processNoise] es el ruido del proceso Q (por defecto 0.01).
  SimpleKalmanFilter2D({
    this.processNoise = 0.01,
  })  : _p11 = 1.0,
        _p12 = 0.0,
        _p21 = 0.0,
        _p22 = 1.0,
        _initialized = false;

  /// Aplica el paso de actualización del filtro con una nueva lectura.
  /// Retorna la lectura filtrada.
  GpsReading update(GpsReading reading) {
    final measurementNoise = reading.horizontalAccuracy *
        reading.horizontalAccuracy;

    if (!_initialized) {
      _lat = reading.latitude;
      _lon = reading.longitude;
      _p11 = 1.0;
      _p12 = 0.0;
      _p21 = 0.0;
      _p22 = 1.0;
      _initialized = true;
      return reading;
    }

    _predict();
    _update(
      reading.latitude,
      reading.longitude,
      measurementNoise,
    );

    return reading.copyWith(
      latitude: _lat,
      longitude: _lon,
    );
  }

  /// Reinicia el filtro a su estado inicial.
  void reset() {
    _lat = null;
    _lon = null;
    _p11 = 1.0;
    _p12 = 0.0;
    _p21 = 0.0;
    _p22 = 1.0;
    _initialized = false;
  }

  /// Retorna el estado actual del filtro como una lectura GPS, o null si no está inicializado.
  GpsReading? get currentState {
    if (!_initialized || _lat == null || _lon == null) return null;
    return GpsReading(
      latitude: _lat!,
      longitude: _lon!,
      altitude: 0.0,
      horizontalAccuracy: sqrt(_p11),
      altitudeAccuracy: sqrt(_p22),
      speed: 0.0,
      timestamp: DateTime.now(),
    );
  }

  void _predict() {
    _p11 += processNoise;
    _p22 += processNoise;
  }

  void _update(double zLat, double zLon, double r) {
    final yLat = zLat - _lat!;
    final yLon = zLon - _lon!;

    final s11 = _p11 + r;
    final s22 = _p22 + r;

    final k11 = _p11 / s11;
    final k22 = _p22 / s22;

    _lat = _lat! + k11 * yLat;
    _lon = _lon! + k22 * yLon;

    _p11 = (1 - k11) * _p11;
    _p12 = (1 - k11) * _p12;
    _p21 = (1 - k22) * _p21;
    _p22 = (1 - k22) * _p22;
  }
}
