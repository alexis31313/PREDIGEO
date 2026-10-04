import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/errors/exceptions.dart';
import '../../domain/entities/gps_reading.dart';

/// Servicio de ubicación para PrediGeo.
/// Gestiona el acceso a la ubicación GPS del dispositivo usando geolocator
/// y permission_handler. Proporciona verificación de permisos, obtención de
/// posición actual, stream de actualizaciones en tiempo real y seguimiento
/// continuo con caché de la última lectura conocida.
class LocationService {
  StreamSubscription<GpsReading>? _positionSubscription;
  GpsReading? _latestReading;

  /// Verifica si el servicio de ubicación GPS está habilitado en el dispositivo.
  Future<bool> isServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      throw LocationException(
        'No se pudo verificar si el servicio de ubicación está habilitado: $e',
      );
    }
  }

  /// Verifica el estado actual del permiso de ubicación.
  /// Retorna 'granted', 'denied', 'deniedForever' o 'unknown'.
  Future<String> checkPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      return _mapPermissionToString(permission);
    } catch (e) {
      throw PermissionException(
        'No se pudo verificar el permiso de ubicación: $e',
      );
    }
  }

  /// Solicita el permiso de ubicación al usuario.
  /// Si el permiso fue denegado permanentemente, abre la configuración de la app.
  /// Retorna 'granted', 'denied', 'deniedForever' o 'unknown'.
  Future<String> requestPermission() async {
    try {
      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        await openAppSettings();
        return 'deniedForever';
      }

      return _mapPermissionToString(permission);
    } catch (e) {
      throw PermissionException(
        'No se pudo solicitar el permiso de ubicación: $e',
      );
    }
  }

  /// Obtiene la posición actual del dispositivo con la mejor precisión disponible.
  /// Retorna un GpsReading con los datos de la posición.
  Future<GpsReading> getCurrentReading() async {
    try {
      final serviceEnabled = await isServiceEnabled();
      if (!serviceEnabled) {
        throw LocationException(
          'El servicio de ubicación está deshabilitado. '
          'Active el GPS del dispositivo para continuar.',
        );
      }

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied) {
          throw PermissionException(
            'El permiso de ubicación fue denegado. '
            'Se requiere permiso para obtener la posición.',
          );
        }
        if (requested == LocationPermission.deniedForever) {
          throw PermissionException(
            'El permiso de ubicación fue denegado permanentemente. '
            'Debe habilitarlo manualmente en la configuración de la aplicación.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw PermissionException(
          'El permiso de ubicación fue denegado permanentemente. '
          'Debe habilitarlo manualmente en la configuración de la aplicación.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      return GpsReading.fromPosition(position);
    } on LocationException {
      rethrow;
    } on PermissionException {
      rethrow;
    } catch (e) {
      throw LocationException(
        'No se pudo obtener la posición actual: $e',
      );
    }
  }

  /// Retorna un stream de actualizaciones de posición en tiempo real.
  /// Utiliza la mejor precisión, sin filtro de distancia y configuración
  /// de Android con notificación en primer plano.
  Stream<GpsReading> getReadingStream() {
    try {
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      );

      return Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).map((position) => GpsReading.fromPosition(position));
    } catch (e) {
      throw LocationException(
        'No se pudo iniciar el stream de ubicación: $e',
      );
    }
  }

  /// Inicia el seguimiento de ubicación en tiempo real.
  /// Escucha el stream de posiciones y almacena la última lectura conocida.
  void startTracking() {
    _positionSubscription?.cancel();

    _positionSubscription = getReadingStream().listen(
      (reading) {
        _latestReading = reading;
      },
      onError: (error) {
        if (error is LocationException) {
          throw LocationException(error.message);
        }
        if (error is PermissionException) {
          throw PermissionException(error.message);
        }
        throw LocationException(
          'Error durante el seguimiento de ubicación: $error',
        );
      },
    );
  }

  /// Detiene el seguimiento de ubicación y cancela la suscripción al stream.
  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  /// Retorna la última lectura GPS conocida, o null si no hay ninguna.
  GpsReading? get latestReading => _latestReading;

  /// Convierte un objeto LocationPermission de geolocator a su representación en String.
  String _mapPermissionToString(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return 'granted';
      case LocationPermission.denied:
        return 'denied';
      case LocationPermission.deniedForever:
        return 'deniedForever';
      default:
        return 'unknown';
    }
  }
}
