/// Clases de excepción para PrediGeo.
/// Representan errores técnicos con mensajes descriptivos en español.

/// Excepción relacionada con errores del servidor o API remota.
class ServerException implements Exception {
  final String message;

  const ServerException([
    this.message = 'Ocurrió un error en el servidor. Intente nuevamente más tarde.',
  ]);

  @override
  String toString() => 'ServerException: $message';
}

/// Excepción relacionada con errores de caché local.
class CacheException implements Exception {
  final String message;

  const CacheException([
    this.message = 'No se pudo acceder a los datos almacenados localmente.',
  ]);

  @override
  String toString() => 'CacheException: $message';
}

/// Excepción relacionada con errores de ubicación GPS.
class LocationException implements Exception {
  final String message;

  const LocationException([
    this.message = 'No se pudo obtener la ubicación del dispositivo.',
  ]);

  @override
  String toString() => 'LocationException: $message';
}

/// Excepción relacionada con permisos no concedidos por el usuario.
class PermissionException implements Exception {
  final String message;

  const PermissionException([
    this.message = 'Permiso denegado. Se requieren permisos para continuar.',
  ]);

  @override
  String toString() => 'PermissionException: $message';
}

/// Excepción relacionada con validación de datos de entrada.
class ValidationException implements Exception {
  final String message;

  const ValidationException([
    this.message = 'Los datos ingresados no son válidos.',
  ]);

  @override
  String toString() => 'ValidationException: $message';
}

/// Excepción relacionada con errores de la base de datos local.
class DatabaseException implements Exception {
  final String message;

  const DatabaseException([
    this.message = 'Ocurrió un error al acceder a la base de datos.',
  ]);

  @override
  String toString() => 'DatabaseException: $message';
}

/// Excepción relacionada con errores al exportar datos o archivos.
class ExportException implements Exception {
  final String message;

  const ExportException([
    this.message = 'No se pudo exportar los datos. Intente nuevamente.',
  ]);

  @override
  String toString() => 'ExportException: $message';
}
