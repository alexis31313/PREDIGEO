// Proveedores de la capa de captura: servicio de puntos y control de pantalla.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/wake_lock_service.dart';
import '../../domain/usecases/signal_processing/point_capture_service.dart';
import 'gps_state_notifier.dart';

/// Servicio de captura de puntos basado en el servicio de ubicación compartido.
final pointCaptureServiceProvider = Provider<PointCaptureService>((ref) {
  return PointCaptureService(
    locationService: ref.watch(locationServiceProvider),
  );
});

/// Servicio para mantener la pantalla encendida durante la captura.
final wakeLockServiceProvider = Provider<WakeLockService>((ref) {
  return const WakeLockService();
});
