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
    final completer = Completer<CapturedPoint>();

    late StreamSubscription subscription;
    Timer? timeoutTimer;

    timeoutTimer = Timer(timeout, () {
      if (!completer.isCompleted) {
        subscription.cancel();
        if (validReadings.length < 3) {
          completer.completeError(
            InsufficientSamplesException(
              'No se obtuvieron suficientes muestras válidas. '
              'Se obtuvieron ${validReadings.length}, se requieren al menos 3. '
              'Verifique la señal GPS e intente nuevamente.',
            ),
          );
        } else {
          completer.complete(_buildCapturedPoint(validReadings));
        }
      }
    });

    subscription = locationService.getReadingStream().listen(
      (reading) {
        if (completer.isCompleted) return;

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

          if (validReadings.length >= samples) {
            timeoutTimer?.cancel();
            subscription.cancel();
            if (!completer.isCompleted) {
              completer.complete(_buildCapturedPoint(validReadings));
            }
          }
        }
      },
      onError: (error) {
        timeoutTimer?.cancel();
        if (!completer.isCompleted) {
          completer.completeError(
            InsufficientSamplesException(
              'Error durante la captura de muestras: $error',
            ),
          );
        }
      },
    );

    return completer.future;
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
