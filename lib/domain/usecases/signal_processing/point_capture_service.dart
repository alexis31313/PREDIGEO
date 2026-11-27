import 'dart:async';

import '../../entities/gps_reading.dart';
import '../../../data/datasources/location_service.dart';
import 'captured_point.dart';
import 'outlier_filter.dart';
import 'simple_kalman_filter.dart';
import 'weighted_averager.dart';

/// Servicio de captura de puntos GPS.
/// Recolecta múltiples lecturas del dispositivo, las filtra, las promedia
/// y retorna un punto capturado con precisión estimada.
class PointCaptureService {
  final LocationService locationService;
  final OutlierFilter outlierFilter;
  final WeightedAverager weightedAverager;
  final SimpleKalmanFilter2D? kalmanFilter;

  /// Muestreador opcional de presión atmosférica (hPa). Se ejecuta en
  /// paralelo con las lecturas GPS; devuelve `null` si no hay barómetro.
  final Future<double?> Function()? pressureSampler;

  /// Crea un servicio de captura de puntos.
  /// [locationService] es el servicio de ubicación a utilizar.
  /// [outlierFilter] es el filtro de valores atípicos (por defecto OutlierFilter()).
  /// [weightedAverager] es el promediador ponderado (por defecto WeightedAverager()).
  /// [kalmanFilter] es un filtro de Kalman opcional para suavizar las lecturas.
  PointCaptureService({
    required this.locationService,
    OutlierFilter? outlierFilter,
    WeightedAverager? weightedAverager,
    SimpleKalmanFilter2D? kalmanFilter,
    this.pressureSampler,
  })  : outlierFilter = outlierFilter ?? OutlierFilter(),
        weightedAverager = weightedAverager ?? const WeightedAverager(),
        kalmanFilter = kalmanFilter;

  /// Captura un punto GPS recolectando múltiples muestras.
  /// [samples] es el número de muestras deseadas (por defecto 10).
  /// [timeout] es el tiempo máximo de espera (por defecto 30 segundos).
  /// [onProgress] es un callback opcional que recibe el progreso (0.0 a 1.0).
  /// Retorna un CapturedPoint con las coordenadas promediadas.
  /// Lanza InsufficientSamplesException si no se obtienen suficientes muestras válidas.
  Future<CapturedPoint> capturePoint({
    int samples = 10,
    Duration timeout = const Duration(seconds: 30),
    void Function(double progress)? onProgress,
  }) async {
    final validReadings = <GpsReading>[];
    var totalReadings = 0;
    var lastAccuracy = 0.0;
    final stopwatch = Stopwatch()..start();
    final pressureFuture = _startPressureSampling();

    while (validReadings.length < samples && stopwatch.elapsed < timeout) {
      try {
        final reading = await locationService.getCurrentReading();
        totalReadings++;
        lastAccuracy = reading.horizontalAccuracy;

        final previous = validReadings.isEmpty ? null : validReadings.last;
        if (outlierFilter.filterSingle(reading, previous)) {
          var filtered = reading;
          if (kalmanFilter != null) {
            filtered = kalmanFilter!.update(filtered);
          }
          validReadings.add(filtered);

          onProgress?.call(
            (validReadings.length / samples).clamp(0.0, 1.0),
          );
        }
      } catch (_) {
        // Ignorar errores individuales y reintentar en el siguiente ciclo.
      }

      if (validReadings.length < samples && stopwatch.elapsed < timeout) {
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    if (validReadings.length < 3) {
      throw InsufficientSamplesException(
        _insufficientMessage(validReadings.length, totalReadings, lastAccuracy),
      );
    }

    final point = _buildCapturedPoint(validReadings);
    final pressure = await pressureFuture;
    return pressure == null ? point : point.copyWith(pressureHpa: pressure);
  }

  Future<double?> _startPressureSampling() async {
    final sampler = pressureSampler;
    if (sampler == null) return null;
    try {
      return await sampler();
    } catch (_) {
      return null;
    }
  }

  String _insufficientMessage(int valid, int total, double lastAccuracy) {
    if (total == 0) {
      return 'No se recibieron lecturas GPS. '
          'Verifique que el GPS esté activo y que la aplicación tenga '
          'permiso de ubicación, luego intente de nuevo.';
    }
    if (valid == 0) {
      return 'Se recibieron $total lecturas GPS pero ninguna con precisión '
          'suficiente (última: ${lastAccuracy.toStringAsFixed(1)} m, '
          'umbral 20 m). Salga a un sitio despejado e intente de nuevo.';
    }
    return 'No se obtuvieron suficientes muestras válidas. '
        'Se obtuvieron $valid de $total, se requieren al menos 3. '
        'Verifique la señal GPS e intente nuevamente.';
  }

  CapturedPoint _buildCapturedPoint(List<GpsReading> readings) {
    final averaged = weightedAverager.average(readings);

    return CapturedPoint(
      latitude: averaged.latitude,
      longitude: averaged.longitude,
      altitude: averaged.altitude,
      estimatedAccuracy: averaged.horizontalAccuracy,
      sampleCount: readings.length,
      timestamp: DateTime.now(),
    );
  }
}

/// Excepción lanzada cuando no se obtienen suficientes muestras válidas.
class InsufficientSamplesException implements Exception {
  final String message;

  const InsufficientSamplesException(this.message);

  @override
  String toString() => 'InsufficientSamplesException: $message';
}
