/// Gestor de la base de datos local SQLite de PrediGeo.
///
/// Responsabilidades:
/// - abrir y cerrar la base de datos (patrón Singleton con inicialización perezosa);
/// - crear el esquema versionado ([schemaVersion]) mediante `onCreate`;
/// - migrar esquemas anteriores mediante `onUpgrade`;
/// - activar las claves foráneas en cada conexión (`PRAGMA foreign_keys`);
/// - exponer operaciones CRUD genéricas sobre `DatabaseExecutor`, de modo que
///   el repositorio de la capa de datos resuelva la lógica de negocio.
///
/// La clase es deliberadamente agnóstica al modelo de datos: no conoce
/// entidades ni conversiones. Para ejecutar pruebas unitarias se puede inyectar
/// una fábrica de bases de datos distinta (por ejemplo `databaseFactoryFfi`).
library;

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart' as app_errors;
import '../../domain/entities/measurement_enums.dart';
import '../models/sqlite_values.dart';

/// Acceso singleton a la base de datos SQLite local.
///
/// Uso habitual en la aplicación:
///
/// ```dart
/// final db = await DatabaseHelper.instance.database;
/// ```
///
/// En pruebas unitarias se construye una instancia aislada:
///
/// ```dart
/// sqfliteFfiInit();
/// final helper = DatabaseHelper.forTesting(
///   databasePath: inMemoryDatabasePath,
///   factory: databaseFactoryFfi,
/// );
/// ```
class DatabaseHelper {
  DatabaseHelper._({
    String? databasePath,
    DatabaseFactory? factory,
    this.databaseName = AppConstants.databaseName,
  })  : _databasePath = databasePath,
        _factory = factory;

  /// Crea una instancia independiente, pensada para pruebas unitarias.
  ///
  /// [databasePath] permite fijar la ruta (por ejemplo `inMemoryDatabasePath` o
  /// un archivo temporal) y [factory] la implementación de SQLite a utilizar.
  factory DatabaseHelper.forTesting({
    String? databasePath,
    DatabaseFactory? factory,
    String databaseName = AppConstants.databaseName,
  }) {
    return DatabaseHelper._(
      databasePath: databasePath,
      factory: factory,
      databaseName: databaseName,
    );
  }

  /// Nombre del archivo de base de datos.
  final String databaseName;

  final String? _databasePath;
  final DatabaseFactory? _factory;
  Database? _database;

  static DatabaseHelper? _instance;

  /// Instancia única utilizada por la aplicación.
  static DatabaseHelper get instance => _instance ??= DatabaseHelper._();

  /// Sustituye la instancia global. Pensado para pruebas; pasar `null` restaura
  /// el comportamiento normal (se creará una instancia nueva bajo demanda).
  static void overrideInstance(DatabaseHelper? helper) => _instance = helper;

  /// Versión actual del esquema. Todo cambio de estructura debe incrementarla y
  /// añadir su migración en [_onUpgrade].
  static const int schemaVersion = AppConstants.databaseVersion;

  /// Conexión abierta a la base de datos. Se crea en el primer acceso.
  Future<Database> get database async {
    final current = _database;
    if (current != null && current.isOpen) return current;

    final factory = _factory ?? databaseFactory;
    final path =
        _databasePath ?? p.join(await factory.getDatabasesPath(), databaseName);

    try {
      final opened = await factory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: schemaVersion,
          onConfigure: _onConfigure,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
          onDowngrade: _onDowngrade,
        ),
      );
      _database = opened;
      return opened;
    } on DatabaseException catch (error) {
      throw app_errors.DatabaseException(
        'No se pudo abrir la base de datos local "$databaseName": ${error.toString()}',
      );
    }
  }

  /// Cierra la conexión. Es seguro invocarlo aunque la base nunca se abrió.
  Future<void> close() async {
    final current = _database;
    _database = null;
    if (current != null && current.isOpen) {
      await current.close();
    }
  }

  // ---------------------------------------------------------------------------
  // Configuración y esquema
  // ---------------------------------------------------------------------------

  /// Se ejecuta en cada apertura. Sin esto SQLite ignora las claves foráneas,
  /// que no están habilitadas por defecto.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Crea el esquema completo en una base de datos nueva.
  Future<void> _onCreate(Database db, int version) async {
    await _createSchema(db);
  }

  /// Migra el esquema desde [oldVersion] hasta la versión actual.
  ///
  /// Las migraciones son acumulativas y se aplican en orden ascendente. Al
  /// terminar se ejecuta [_ensureIndexes] para crear cualquier índice nuevo.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // v1 -> v2: se conservan los datos del esquema heredado.
    if (oldVersion < 2) {
      await _migrateV1ToV2(db);
    }

    await _ensureIndexes(db);
  }

  /// Ante un esquema más nuevo que el de la app (por ejemplo, tras una
  /// restauración de copia de seguridad) se reinicia el almacenamiento local.
  ///
  /// Es una operación destructiva y deliberadamente explícita: los datos GPS
  /// pueden volver a capturarse, mientras que una incompatibilidad silenciosa
  /// produciría lecturas corruptas.
  Future<void> _onDowngrade(Database db, int oldVersion, int newVersion) async {
    await db
        .execute('DROP TABLE IF EXISTS ${AppConstants.tableFieldEvaluations}');
    await db
        .execute('DROP TABLE IF EXISTS ${AppConstants.tableMeasurementPoints}');
    await db.execute('DROP TABLE IF EXISTS ${AppConstants.tableMeasurements}');
    await _createSchema(db);
  }

  /// Crea tablas e índices. Todas las sentencias usan `IF NOT EXISTS` para que
  /// la creación sea idempotente y reutilizable desde las migraciones.
  Future<void> _createSchema(DatabaseExecutor db) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableMeasurements} (
        ${AppConstants.columnId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${AppConstants.columnName} TEXT NOT NULL CHECK (length(trim(${AppConstants.columnName})) > 0),
        ${AppConstants.columnType} TEXT NOT NULL
          CHECK (${AppConstants.columnType} IN ('area', 'path')),
        ${AppConstants.columnAreaM2} REAL
          CHECK (${AppConstants.columnAreaM2} IS NULL OR ${AppConstants.columnAreaM2} >= 0),
        ${AppConstants.columnPerimeterM} REAL
          CHECK (${AppConstants.columnPerimeterM} IS NULL OR ${AppConstants.columnPerimeterM} >= 0),
        ${AppConstants.columnDistanceM} REAL
          CHECK (${AppConstants.columnDistanceM} IS NULL OR ${AppConstants.columnDistanceM} >= 0),
        ${AppConstants.columnMode} TEXT NOT NULL
          CHECK (${AppConstants.columnMode} IN ('online', 'offline')),
        ${AppConstants.columnCategory} TEXT
          CHECK (${AppConstants.columnCategory} IS NULL OR ${AppConstants.columnCategory} IN ('rural_open', 'rural_vegetation', 'urban')),
        ${AppConstants.columnNotes} TEXT,
        ${AppConstants.columnAvgAccuracyM} REAL
          CHECK (${AppConstants.columnAvgAccuracyM} IS NULL OR ${AppConstants.columnAvgAccuracyM} >= 0),
        ${AppConstants.columnCreatedAt} TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableMeasurementPoints} (
        ${AppConstants.columnId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${AppConstants.columnMeasurementId} INTEGER NOT NULL,
        ${AppConstants.columnSeq} INTEGER NOT NULL CHECK (${AppConstants.columnSeq} >= 0),
        ${AppConstants.columnLatitude} REAL NOT NULL
          CHECK (${AppConstants.columnLatitude} BETWEEN -90 AND 90),
        ${AppConstants.columnLongitude} REAL NOT NULL
          CHECK (${AppConstants.columnLongitude} BETWEEN -180 AND 180),
        ${AppConstants.columnAltitude} REAL NOT NULL,
        ${AppConstants.columnAccuracy} REAL NOT NULL
          CHECK (${AppConstants.columnAccuracy} >= 0),
        ${AppConstants.columnTimestamp} TEXT NOT NULL,
        FOREIGN KEY (${AppConstants.columnMeasurementId})
          REFERENCES ${AppConstants.tableMeasurements} (${AppConstants.columnId})
          ON DELETE CASCADE ON UPDATE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableFieldEvaluations} (
        ${AppConstants.columnId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${AppConstants.columnMeasurementId} INTEGER NOT NULL,
        ${AppConstants.columnReferenceValue} REAL NOT NULL,
        ${AppConstants.columnReferenceSource} TEXT,
        ${AppConstants.columnReferenceType} TEXT NOT NULL
          CHECK (${AppConstants.columnReferenceType} IN ('area', 'distance')),
        ${AppConstants.columnEnvConditions} TEXT,
        FOREIGN KEY (${AppConstants.columnMeasurementId})
          REFERENCES ${AppConstants.tableMeasurements} (${AppConstants.columnId})
          ON DELETE CASCADE ON UPDATE CASCADE
      )
    ''');

    await batch.commit(noResult: true);
    await _ensureIndexes(db);
  }

  /// Crea los índices de la versión actual.
  Future<void> _ensureIndexes(DatabaseExecutor db) async {
    final batch = db.batch();

    // Historial: siempre se consulta ordenado por fecha descendente.
    batch.execute(
      'CREATE INDEX IF NOT EXISTS ${AppConstants.indexMeasurementsCreatedAt} '
      'ON ${AppConstants.tableMeasurements} (${AppConstants.columnCreatedAt} DESC)',
    );

    // Índice único por (medición, orden): cubre las consultas por
    // measurement_id (prefijo izquierdo) y evita puntos duplicados en el mismo
    // lugar de la secuencia.
    batch.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS ${AppConstants.indexMeasurementPointsSeq} '
      'ON ${AppConstants.tableMeasurementPoints} '
      '(${AppConstants.columnMeasurementId}, ${AppConstants.columnSeq})',
    );

    batch.execute(
      'CREATE INDEX IF NOT EXISTS ${AppConstants.indexFieldEvaluationsMeasurementId} '
      'ON ${AppConstants.tableFieldEvaluations} (${AppConstants.columnMeasurementId})',
    );

    await batch.commit(noResult: true);
  }

  /// Migración del esquema heredado (v1) al esquema actual (v2), conservando
  /// los datos ya capturados.
  ///
  /// Pasos:
  /// 1. Se leen las mediciones y coordenadas heredadas en memoria (el volumen
  ///    local es pequeño: decenas de filas).
  /// 2. Se eliminan las tablas heredadas y se crea el esquema actual.
  /// 3. Se reinscriben las mediciones, conservando sus `id`:
  ///    - `created_at` (epoch en milisegundos) pasa a ISO8601 UTC;
  ///    - `measurement_type` se traduce a `type`
  ///      (`polygon`/`area` -> `area`, cualquier otro -> `path`);
  ///    - las mediciones heredadas se marcan como `mode = 'offline'`;
  ///    - `avg_accuracy_m` se calcula con el promedio de `accuracy` de sus
  ///      puntos;
  ///    - `category` queda en `NULL` porque el esquema heredado no lo
  ///      implementaba.
  /// 4. Se reinscriben los puntos, renumerando `seq` desde 0 en el orden de
  ///    captura (`timestamp` y, a igualdad de tiempo, `id`).
  ///
  /// Los puntos huérfanos del esquema heredado (sin `measurement_id` o cuya
  /// medición no existe) se descartan: la integridad referencial del esquema
  /// actual no admite filas colgantes.
  ///
  /// Todo se ejecuta dentro de la transacción que sqflite abre para `onUpgrade`:
  /// si algo falla, el esquema original queda intacto.
  Future<void> _migrateV1ToV2(Database db) async {
    final legacyMeasurements = await db.query(AppConstants.tableMeasurements);
    final legacyPoints = await db.query(AppConstants.legacyTableCoordinates);

    await db
        .execute('DROP TABLE IF EXISTS ${AppConstants.legacyTableCoordinates}');
    await db
        .execute('DROP TABLE IF EXISTS ${AppConstants.legacyTableSessions}');
    await db.execute('DROP TABLE IF EXISTS ${AppConstants.tableMeasurements}');

    await _createSchema(db);

    // Índice de puntos por medición, preservando el orden de captura heredado.
    final pointsByMeasurement = <int, List<Map<String, Object?>>>{};
    for (final point in legacyPoints) {
      final measurementId = _asInt(point[AppConstants.columnMeasurementId]);
      if (measurementId != null) {
        pointsByMeasurement.putIfAbsent(measurementId, () => []).add(point);
      }
    }
    for (final points in pointsByMeasurement.values) {
      points.sort((a, b) {
        final byTime = (_asInt(a[AppConstants.legacyColumnTimestamp]) ?? 0)
            .compareTo(_asInt(b[AppConstants.legacyColumnTimestamp]) ?? 0);
        if (byTime != 0) return byTime;
        return (_asInt(a[AppConstants.columnId]) ?? 0)
            .compareTo(_asInt(b[AppConstants.columnId]) ?? 0);
      });
    }

    for (final legacy in legacyMeasurements) {
      final id = _asInt(legacy[AppConstants.columnId]);
      if (id == null) continue;

      final points = pointsByMeasurement[id] ?? const <Map<String, Object?>>[];
      var accuracySum = 0.0;
      for (final point in points) {
        accuracySum += _asDouble(point[AppConstants.columnAccuracy]) ?? 0.0;
      }

      await db.insert(
        AppConstants.tableMeasurements,
        <String, Object?>{
          AppConstants.columnId: id,
          AppConstants.columnName: legacy[AppConstants.columnName],
          AppConstants.columnType: _mapLegacyType(
            legacy[AppConstants.legacyColumnMeasurementType],
          ),
          AppConstants.columnAreaM2:
              _asDouble(legacy[AppConstants.legacyColumnArea]),
          AppConstants.columnPerimeterM:
              _asDouble(legacy[AppConstants.legacyColumnPerimeter]),
          AppConstants.columnDistanceM:
              _asDouble(legacy[AppConstants.legacyColumnDistance]),
          AppConstants.columnMode: MeasurementMode.offline.value,
          AppConstants.columnCategory: null,
          AppConstants.columnNotes: legacy[AppConstants.columnNotes],
          AppConstants.columnAvgAccuracyM:
              points.isEmpty ? null : accuracySum / points.length,
          AppConstants.columnCreatedAt: SqliteValues.dateTimeToText(
            DateTime.fromMillisecondsSinceEpoch(
              _asInt(legacy[AppConstants.legacyColumnCreatedAt]) ?? 0,
              isUtc: true,
            ),
          ),
        },
      );

      for (var seq = 0; seq < points.length; seq++) {
        final point = points[seq];
        await db.insert(
          AppConstants.tableMeasurementPoints,
          <String, Object?>{
            AppConstants.columnMeasurementId: id,
            AppConstants.columnSeq: seq,
            AppConstants.columnLatitude:
                _asDouble(point[AppConstants.columnLatitude]) ?? 0.0,
            AppConstants.columnLongitude:
                _asDouble(point[AppConstants.columnLongitude]) ?? 0.0,
            AppConstants.columnAltitude:
                _asDouble(point[AppConstants.columnAltitude]) ?? 0.0,
            AppConstants.columnAccuracy:
                _asDouble(point[AppConstants.columnAccuracy]) ?? 0.0,
            AppConstants.columnTimestamp: SqliteValues.dateTimeToText(
              DateTime.fromMillisecondsSinceEpoch(
                _asInt(point[AppConstants.legacyColumnTimestamp]) ?? 0,
                isUtc: true,
              ),
            ),
          },
        );
      }
    }
  }

  /// Traduce el `measurement_type` heredado al `type` del esquema actual.
  String _mapLegacyType(Object? raw) {
    final value = raw?.toString().toLowerCase().trim() ?? '';
    const areaTypes = <String>{'polygon', 'poligono', 'área', 'area'};
    return areaTypes.contains(value)
        ? MeasurementType.area.value
        : MeasurementType.path.value;
  }

  int? _asInt(Object? value) => value == null ? null : (value as num).toInt();

  double? _asDouble(Object? value) =>
      value == null ? null : (value as num).toDouble();

  // ---------------------------------------------------------------------------
  // Operaciones genéricas
  // ---------------------------------------------------------------------------

  /// Inserta una fila y devuelve el `id` generado.
  Future<int> insert(String table, Map<String, Object?> values) async {
    final db = await database;
    return db.insert(table, values);
  }

  /// Consulta filas de una tabla.
  Future<List<Map<String, Object?>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return db.query(
      table,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  /// Actualiza filas y devuelve la cantidad actualizada.
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    required String where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return db.update(table, values, where: where, whereArgs: whereArgs);
  }

  /// Elimina filas y devuelve la cantidad eliminada.
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return db.delete(table, where: where, whereArgs: whereArgs);
  }

  /// Cuenta filas de una tabla aplicando un filtro opcional.
  Future<int> count(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM $table'
      '${where == null ? '' : ' WHERE $where'}',
      whereArgs,
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  /// Ejecuta [action] dentro de una transacción atómica.
  ///
  /// Cualquier error lanzado por [action] provoca la reversión completa de las
  /// operaciones realizadas dentro de la transacción.
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return db.transaction(action);
  }
}
