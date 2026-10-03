/// Clases de fallo (failures) para PrediGeo.
/// Representan errores del dominio con mensajes descriptivos en español.

/// Clase base abstracta para todos los fallos del dominio.
abstract class Failure {
  final String message;

  const Failure(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// Fallo relacionado con errores del servidor o API remota.
class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'Ocurrió un error en el servidor. Intente nuevamente más tarde.',
  ]);
}

/// Fallo relacionado con errores de caché local.
class CacheFailure extends Failure {
  const CacheFailure([
    super.message = 'No se pudo acceder a los datos almacenados localmente.',
  ]);
}

/// Fallo relacionado con errores de ubicación GPS.
class LocationFailure extends Failure {
  const LocationFailure([
    super.message = 'No se pudo obtener la ubicación del dispositivo.',
  ]);
}

/// Fallo relacionado con permisos no concedidos por el usuario.
class PermissionFailure extends Failure {
  const PermissionFailure([
    super.message = 'Permiso denegado. Se requieren permisos para continuar.',
  ]);
}

/// Fallo relacionado con validación de datos de entrada.
class ValidationFailure extends Failure {
  const ValidationFailure([
    super.message = 'Los datos ingresados no son válidos.',
  ]);
}

/// Fallo relacionado con errores de la base de datos local.
class DatabaseFailure extends Failure {
  const DatabaseFailure([
    super.message = 'Ocurrió un error al acceder a la base de datos.',
  ]);
}

/// Fallo relacionado con errores al exportar datos o archivos.
class ExportFailure extends Failure {
  const ExportFailure([
    super.message = 'No se pudo exportar los datos. Intente nuevamente.',
  ]);
}
