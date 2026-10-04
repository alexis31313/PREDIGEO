/// Constantes globales de la aplicación PrediGeo.
/// Define nombres de base de datos, tablas, índices, valores por defecto y formatos.
///
/// La capa de persistencia local (SQLite) es totalmente offline-first:
/// toda la información de mediciones, puntos y evaluaciones de campo vive
/// en el dispositivo. No existe ninguna dependencia de red en este módulo.
class AppConstants {
  AppConstants._();

  static const String appName = 'PrediGeo';
  static const String databaseName = 'predigeo.db';

  /// Versión 2 del esquema local.
  ///
  /// - v1: esquema heredado (`measurements` con columnas `area`, `perimeter`,
  ///   `distance`, `coordinate_count`, `measurement_type`, `created_at` INTEGER;
  ///   tabla `coordinates`; tabla `measurement_sessions`).
  /// - v2: esquema actual (`measurements`, `measurement_points`, `field_evaluations`)
  ///   con fechas ISO8601 UTC, modo de captura, categoría de terreno,
  ///   precisión media y evaluaciones de campo.
  ///
  /// La migración v1 -> v2 la realiza [DatabaseHelper] conservando los datos
  /// capturados previamente.
  static const int databaseVersion = 2;

  // ---------------------------------------------------------------------------
  // Tablas
  // ---------------------------------------------------------------------------
  static const String tableMeasurements = 'measurements';
  static const String tableMeasurementPoints = 'measurement_points';
  static const String tableFieldEvaluations = 'field_evaluations';

  // Tablas del esquema heredado (v1), usadas solo dentro de la migración v1 -> v2.
  // `measurements` comparte nombre con la tabla actual: la migración lee sus
  // filas, la elimina y reconstruye el esquema con el nombre definitivo.
  static const String legacyTableCoordinates = 'coordinates';
  static const String legacyTableSessions = 'measurement_sessions';

  // ---------------------------------------------------------------------------
  // Índices
  // ---------------------------------------------------------------------------
  /// Historial ordenado de más reciente a más antiguo.
  static const String indexMeasurementsCreatedAt =
      'idx_measurements_created_at';

  /// Índice único y de orden de los puntos: cubre búsquedas por
  /// `measurement_id` (prefijo izquierdo) y garantiza `seq` único por medición.
  static const String indexMeasurementPointsSeq =
      'idx_measurement_points_measurement_seq';

  /// Búsqueda de evaluaciones asociadas a una medición.
  static const String indexFieldEvaluationsMeasurementId =
      'idx_field_evaluations_measurement_id';

  // ---------------------------------------------------------------------------
  // Columnas
  // ---------------------------------------------------------------------------
  static const String columnId = 'id';
  static const String columnName = 'name';
  static const String columnType = 'type';
  static const String columnAreaM2 = 'area_m2';
  static const String columnPerimeterM = 'perimeter_m';
  static const String columnDistanceM = 'distance_m';
  static const String columnMode = 'mode';
  static const String columnCategory = 'category';
  static const String columnNotes = 'notes';
  static const String columnAvgAccuracyM = 'avg_accuracy_m';
  static const String columnCreatedAt = 'created_at';

  static const String columnMeasurementId = 'measurement_id';
  static const String columnSeq = 'seq';
  static const String columnLatitude = 'latitude';
  static const String columnLongitude = 'longitude';
  static const String columnAltitude = 'altitude';
  static const String columnAccuracy = 'accuracy';
  static const String columnTimestamp = 'timestamp';

  static const String columnReferenceValue = 'reference_value';
  static const String columnReferenceSource = 'reference_source';
  static const String columnReferenceType = 'reference_type';
  static const String columnEnvConditions = 'env_conditions';

  // ---------------------------------------------------------------------------
  // Columnas del esquema heredado (v1), usadas solo por la migración v1 -> v2
  // ---------------------------------------------------------------------------
  static const String legacyColumnArea = 'area';
  static const String legacyColumnPerimeter = 'perimeter';
  static const String legacyColumnDistance = 'distance';
  static const String legacyColumnCoordinateCount = 'coordinate_count';
  static const String legacyColumnMeasurementType = 'measurement_type';
  static const String legacyColumnCreatedAt = 'created_at';
  static const String legacyColumnTimestamp = 'timestamp';

  // ---------------------------------------------------------------------------
  // Reglas de dominio
  // ---------------------------------------------------------------------------
  static const double defaultGpsAccuracy = 5.0;
  static const double earthRadius = 6371000.0;
  static const int minPolygonPoints = 3;
  static const double maxLatitude = 90.0;
  static const double maxLongitude = 180.0;

  // ---------------------------------------------------------------------------
  // Formatos
  // ---------------------------------------------------------------------------
  static const String dateFormat = 'dd/MM/yyyy HH:mm';

  /// Formato de marca de tiempo en base de datos (UTC, orden lexicográfico).
  static const String iso8601Utc = 'yyyy-MM-ddTHH:mm:ss.SSSZ';
}