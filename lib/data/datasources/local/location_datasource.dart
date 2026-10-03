/// Fuente de datos de ubicación para PrediGeo.
/// Gestiona el acceso a la ubicación GPS del dispositivo usando geolocator.
/// Proporciona verificación de permisos, obtención de posición actual
/// y stream de actualizaciones de posición en tiempo real.
import 'package:geolocator/geolocator.dart';
import '../../../core/errors/exceptions.dart';

class LocationDataSource {
  Future<bool> checkPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } on PermissionException catch (e) {
      throw PermissionException(e.message ?? 'Error de permiso desconocido');
    } catch (e) {
      throw Exception('Error al verificar permisos de ubicación: $e');
    }
  }

  Future<bool> requestPermission() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw PermissionException(
          'Los permisos de ubicación fueron denegados permanentemente. '
          'Debe habilitarlos manualmente en la configuración del dispositivo.',
        );
      }
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } on PermissionException {
      rethrow;
    } catch (e) {
      throw Exception('Error al solicitar permisos de ubicación: $e');
    }
  }

  Future<Position> getCurrentPosition() async {
    try {
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LocationException(
          'Los servicios de ubicación están deshabilitados. '
          'Active el GPS del dispositivo.',
        );
      }

      final hasPermission = await checkPermission();
      if (!hasPermission) {
        final granted = await requestPermission();
        if (!granted) {
          throw PermissionException(
            'Se requieren permisos de ubicación para obtener la posición.',
          );
        }
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } on LocationException {
      rethrow;
    } on PermissionException {
      rethrow;
    } catch (e) {
      throw Exception('Error al obtener la posición actual: $e');
    }
  }

  Stream<Position> getPositionStream() {
    try {
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
        timeLimit: Duration(seconds: 10),
      );

      return Geolocator.getPositionStream(locationSettings: locationSettings)
          .handleError((error) {
        if (error is LocationException) {
          throw LocationException(error.message ?? 'Error de ubicación');
        }
        if (error is PermissionException) {
          throw PermissionException(error.message ?? 'Error de permiso');
        }
        throw Exception('Error en el stream de ubicación: $error');
      });
    } catch (e) {
      throw Exception('Error al iniciar el stream de ubicación: $e');
    }
  }

  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      throw Exception('Error al verificar servicios de ubicación: $e');
    }
  }
}
