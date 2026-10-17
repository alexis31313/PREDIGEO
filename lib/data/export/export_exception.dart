class ExportException implements Exception {
  final String mensaje;

  ExportException(this.mensaje);

  @override
  String toString() => 'ExportException: $mensaje';
}
