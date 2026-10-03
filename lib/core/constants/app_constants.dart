/// Constantes globales de la aplicación PrediGeo.
/// Define nombres de base de datos, tablas, valores por defecto y formatos.
class AppConstants {
  AppConstants._();

  static const String appName = 'PrediGeo';
  static const String databaseName = 'predigeo.db';
  static const int databaseVersion = 1;

  static const String tableCoordinates = 'coordinates';
  static const String tableMeasurements = 'measurements';
  static const String tableSessions = 'measurement_sessions';

  static const double defaultGpsAccuracy = 5.0;
  static const double earthRadius = 6371000.0;
  static const int minPolygonPoints = 3;

  static const String dateFormat = 'dd/MM/yyyy HH:mm';
}
