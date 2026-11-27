// Proveedores de la capa de captura: servicio de puntos y control de pantalla.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/barometer_service.dart';
import '../../data/datasources/wake_lock_service.dart';
import '../../domain/usecases/signal_processing/point_capture_service.dart';
import 'gps_state_notifier.dart';

/// Barómetro del dispositivo (canal nativo propio, sin paquetes).
final barometerServiceProvider = Provider<BarometerService>((ref) {
  return BarometerService();
});

/// Servicio de captura de puntos basado en el servicio de ubicación compartido.
///
/// Si el dispositivo tiene barómetro, cada punto registra además la presión
/// media durante la captura para calcular la altura relativa entre puntos.
final pointCaptureServiceProvider = Provider<PointCaptureService>((ref) {
  final barometer = ref.watch(barometerServiceProvider);
  return PointCaptureService(
    locationService: ref.watch(locationServiceProvider),
    pressureSampler: () => barometer.samplePressure(
      duration: const Duration(seconds: 4),
    ),
  );
});

/// Servicio para mantener la pantalla encendida durante la captura.
final wakeLockServiceProvider = Provider<WakeLockService>((ref) {
  return const WakeLockService();
});
