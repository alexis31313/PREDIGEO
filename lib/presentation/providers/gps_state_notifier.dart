import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/exceptions.dart';
import '../../data/datasources/location_service.dart';
import '../../domain/entities/gps_reading.dart';
import '../../domain/entities/location_status.dart';

/// Proveedor del servicio de ubicación.
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Notificador de estado de ubicación GPS para PrediGeo.
/// Gestiona el ciclo de vida del seguimiento de ubicación, incluyendo
/// verificación de servicios, solicitud de permisos y actualización del estado.
class GpsStateNotifier extends StateNotifier<LocationStatus> {
  final LocationService _locationService;

  GpsStateNotifier(this._locationService)
      : super(const Acquiring());

  /// Inicia el proceso de obtención de ubicación:
  /// 1. Verifica que el servicio GPS esté habilitado.
  /// 2. Verifica y solicita permisos de ubicación.
  /// 3. Inicia el seguimiento en tiempo real.
  /// 4. Actualiza el estado a Ready con la primera lectura.
  Future<void> start() async {
    try {
      final serviceEnabled = await _locationService.isServiceEnabled();
      if (!serviceEnabled) {
        state = const ServiceDisabled(
          message: 'El servicio de ubicación está deshabilitado. '
              'Active el GPS del dispositivo.',
        );
        return;
      }

      var permission = await _locationService.checkPermission();

      if (permission == 'denied') {
        permission = await _locationService.requestPermission();
      }

      if (permission == 'deniedForever') {
        state = const PermissionDenied(
          message: 'El permiso de ubicación fue denegado permanentemente. '
              'Debe habilitarlo en la configuración de la aplicación.',
        );
        return;
      }

      if (permission != 'granted') {
        state = const PermissionDenied(
          message: 'Se requiere permiso de ubicación para continuar.',
        );
        return;
      }

      _locationService.startTracking();

      final reading = await _locationService.getCurrentReading();
      state = Ready(reading: reading);
    } on LocationException catch (e) {
      state = ServiceDisabled(message: e.message);
    } on PermissionException catch (e) {
      state = PermissionDenied(message: e.message);
    } catch (e) {
      state = ServiceDisabled(
        message: 'Ocurrió un error inesperado al obtener la ubicación: $e',
      );
    }
  }

  /// Detiene el seguimiento de ubicación y restablece el estado a Acquiring.
  void stop() {
    _locationService.stopTracking();
    state = const Acquiring();
  }
}

/// Proveedor principal del estado de ubicación GPS.
/// Se descarta automáticamente cuando no hay listeners activos.
final gpsStateNotifierProvider =
    StateNotifierProvider.autoDispose<GpsStateNotifier, LocationStatus>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return GpsStateNotifier(locationService);
});

/// Proveedor de stream de lecturas GPS en tiempo real.
/// Emite objetos GpsReading cada vez que se recibe una nueva posición.
final gpsReadingStreamProvider = StreamProvider.autoDispose<GpsReading>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.getReadingStream();
});
