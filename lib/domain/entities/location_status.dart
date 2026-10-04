import 'gps_reading.dart';

/// Clase sellada que representa el estado del servicio de ubicación.
sealed class LocationStatus {
  const LocationStatus();
}

/// Estado que indica que el permiso de ubicación fue denegado.
class PermissionDenied extends LocationStatus {
  final String? message;

  const PermissionDenied({this.message});
}

/// Estado que indica que el servicio de ubicación está deshabilitado.
class ServiceDisabled extends LocationStatus {
  final String? message;

  const ServiceDisabled({this.message});
}

/// Estado que indica que se está adquiriendo la ubicación del dispositivo.
class Acquiring extends LocationStatus {
  final String? message;

  const Acquiring({this.message});
}

/// Estado que indica que la ubicación está lista y disponible.
class Ready extends LocationStatus {
  final GpsReading? reading;

  const Ready({this.reading});
}

/// Extensión que proporciona el método when para pattern matching.
extension LocationStatusWhen on LocationStatus {
  /// Ejecuta la función correspondiente según el tipo de estado.
  T when<T>({
    required T Function(PermissionDenied status) permissionDenied,
    required T Function(ServiceDisabled status) serviceDisabled,
    required T Function(Acquiring status) acquiring,
    required T Function(Ready status) ready,
  }) {
    return switch (this) {
      PermissionDenied() => permissionDenied(this as PermissionDenied),
      ServiceDisabled() => serviceDisabled(this as ServiceDisabled),
      Acquiring() => acquiring(this as Acquiring),
      Ready() => ready(this as Ready),
    };
  }
}
