/// Implementación SQLite del repositorio de mediciones.
///
/// Traduce las operaciones del contrato de dominio [MeasurementRepository] a
/// consultas sobre la base de datos local, garantizando:
/// - atomicidad: medición, puntos y evaluaciones se escriben en una sola
///   transacción;
/// - integridad referencial: los hijos se eliminan en cascada desde SQLite;
/// - orden estable del historial: `created_at DESC, id DESC`.
library;

import 'package:sqflite/sqflite.dart' as sqflite;

import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../domain/entities/field_evaluation.dart';
import '../../domain/entities/geo_point.dart';
import '../../domain/entities/measurement.dart';
import '../../domain/entities/measurement_enums.dart';
import '../../domain/repositories/measurement_repository.dart';
import '../datasources/database_helper.dart';
import '../models/field_evaluation_model.dart';
import '../models/geo_point_model.dart';
import '../models/measurement_model.dart';

/// Repositorio de mediciones respaldado por la base de datos local SQLite.
class SqliteMeasurementRepository implements MeasurementRepository {
  final DatabaseHelper _databaseHelper;

  const SqliteMeasurementRepository(this._databaseHelper);

  // ---------------------------------------------------------------------------
  // Escrituras
  // ---------------------------------------------------------------------------

  @override
  Future<Measurement> insertMeasurement(Measurement measurement) async {
    _validateMeasurement(measurement);
    _validatePoints(measurement.points);

    final model = MeasurementModel.fromEntity(
      measurement.copyWith(avgAccuracyM: _resolveAvgAccuracy(measurement)),
    );

    try {
      return await _databaseHelper.transaction((txn) async {
        final measurementId = await txn.insert(
          AppConstants.tableMeasurements,
          model.toMap(includeId: false),
        );

        await _insertPoints(txn, measurementId, measurement.points);
        await _insertEvaluations(txn, measurementId, measurement.evaluations);

        final saved = await _loadFullMeasurement(txn, measurementId);
        if (saved == null) {
          throw const DatabaseException(
            'La medición se guardó pero no pudo releerse de la base de datos.',
          );
        }
        return saved;
      });
    } on ValidationException {
      rethrow;
    } on sqflite.DatabaseException catch (error) {
      throw DatabaseException(
        'No se pudo guardar la medición "${measurement.name}": ${error.toString()}',
      );
    }
  }

  @override
  Future<Measurement> update(Measurement measurement) async {
    final id = measurement.id;
    if (id == null) {
      throw const ValidationException(
        'No se puede actualizar una medición que aún no ha sido guardada.',
      );
    }
    _validateMeasurement(measurement);
    _validatePoints(measurement.points);

    final model = MeasurementModel.fromEntity(
      measurement.copyWith(avgAccuracyM: _resolveAvgAccuracy(measurement)),
    );

    try {
      return await _databaseHelper.transaction((txn) async {
        // `created_at` es inmutable: identifica el momento de captura.
        final values = model.toMap(includeId: false)
          ..remove(AppConstants.columnCreatedAt);

        final affected = await txn.update(
          AppConstants.tableMeasurements,
          values,
          where: '${AppConstants.columnId} = ?',
          whereArgs: [id],
        );

        if (affected == 0) {
          throw ValidationException(
            'No existe una medición con el ID $id para actualizar.',
          );
        }

        // Los hijos se reemplazan por completo para mantener la secuencia
        // consistente con lo que el usuario ve en pantalla.
        await txn.delete(
          AppConstants.tableMeasurementPoints,
          where: '${AppConstants.columnMeasurementId} = ?',
          whereArgs: [id],
        );
        await txn.delete(
          AppConstants.tableFieldEvaluations,
          where: '${AppConstants.columnMeasurementId} = ?',
          whereArgs: [id],
        );

        await _insertPoints(txn, id, measurement.points);
        await _insertEvaluations(txn, id, measurement.evaluations);

        final saved = await _loadFullMeasurement(txn, id);
        if (saved == null) {
          throw const DatabaseException(
            'La medición se actualizó pero no pudo releerse de la base de datos.',
          );
        }
        return saved;
      });
    } on ValidationException {
      rethrow;
    } on sqflite.DatabaseException catch (error) {
      throw DatabaseException(
        'No se pudo actualizar la medición con ID $id: ${error.toString()}',
      );
    }
  }

  @override
  Future<void> delete(int id) async {
    try {
      // Los puntos y las evaluaciones se borran en cascada (PRAGMA foreign_keys).
      await _databaseHelper.delete(
        AppConstants.tableMeasurements,
        where: '${AppConstants.columnId} = ?',
        whereArgs: [id],
      );
    } on sqflite.DatabaseException catch (error) {
      throw DatabaseException(
        'No se pudo eliminar la medición con ID $id: ${error.toString()}',
      );
    }
  }

  @override
  Future<int> deleteAll() async {
    try {
      return await _databaseHelper.transaction((txn) async {
        return txn.delete(AppConstants.tableMeasurements);
      });
    } on sqflite.DatabaseException catch (error) {
      throw DatabaseException(
        'No se pudo eliminar el historial de mediciones: ${error.toString()}',
      );
    }
  }

  @override
  Future<FieldEvaluation> insertEvaluation(FieldEvaluation evaluation) async {
    final model = FieldEvaluationModel.fromEntity(evaluation);

    try {
      final id = await _databaseHelper.insert(
        AppConstants.tableFieldEvaluations,
        model.toMap(includeId: false),
      );
      return model.copyWith(id: id).toEntity();
    } on sqflite.DatabaseException catch (error) {
      throw DatabaseException(
        'No se pudo guardar la evaluación de campo de la medición '
        '${evaluation.measurementId}: ${error.toString()}',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Lecturas
  // ---------------------------------------------------------------------------

  @override
  Future<List<Measurement>> getAll() async {
    try {
      final rows = await _databaseHelper.query(
        AppConstants.tableMeasurements,
        orderBy: _orderByCreatedAtDesc,
      );
      return MeasurementModel.toEntities(rows);
    } on sqflite.DatabaseException catch (error) {
      throw DatabaseException(
        'No se pudo obtener el historial de mediciones: ${error.toString()}',
      );
    }
  }

  @override
  Future<Measurement?> getById(int id) async {
    try {
      final db = await _databaseHelper.database;
      return await _loadFullMeasurement(db, id);
    } on sqflite.DatabaseException catch (error) {
      throw DatabaseException(
        'No se pudo obtener la medición con ID $id: ${error.toString()}',
      );
    }
  }

  /// Busca mediciones por nombre.
  ///
  /// Usa `LIKE` con comodines escapados; el `LIKE` de SQLite ya es insensible a
  /// mayúsculas para caracteres ASCII. Un término vacío devuelve todo el
  /// historial.
  @override
  Future<List<Measurement>> search(String? term) async {
    final query = term?.trim() ?? '';
    if (query.isEmpty) return getAll();

    try {
      final rows = await _databaseHelper.query(
        AppConstants.tableMeasurements,
        where: r"name LIKE ? ESCAPE '\'",
        whereArgs: ['%${_escapeLikePattern(query)}%'],
        orderBy: _orderByCreatedAtDesc,
      );
      return MeasurementModel.toEntities(rows);
    } on sqflite.DatabaseException catch (error) {
      throw DatabaseException(
        'No se pudo buscar la medición "$query": ${error.toString()}',
      );
    }
  }

  @override
  Future<List<Measurement>> filter({
    MeasurementType? type,
    MeasurementMode? mode,
    MeasurementCategory? category,
    bool onlyUncategorized = false,
  }) async {
    final clauses = <String>[];
    final args = <Object?>[];

    if (type != null) {
      clauses.add('${AppConstants.columnType} = ?');
      args.add(type.value);
    }

    if (mode != null) {
      clauses.add('${AppConstants.columnMode} = ?');
      args.add(mode.value);
    }

    if (category != null) {
      clauses.add('${AppConstants.columnCategory} = ?');
      args.add(category.value);
    } else if (onlyUncategorized) {
      clauses.add('${AppConstants.columnCategory} IS NULL');
    }

    try {
      final rows = await _databaseHelper.query(
        AppConstants.tableMeasurements,
        where: clauses.isEmpty ? null : clauses.join(' AND '),
        whereArgs: args.isEmpty ? null : args,
        orderBy: _orderByCreatedAtDesc,
      );
      return MeasurementModel.toEntities(rows);
    } on sqflite.DatabaseException catch (error) {
      throw DatabaseException(
        'No se pudo filtrar el historial de mediciones: ${error.toString()}',
      );
    }
  }

  @override
  Future<int> count() async {
    try {
      return await _databaseHelper.count(AppConstants.tableMeasurements);
    } on sqflite.DatabaseException catch (error) {
      throw DatabaseException(
        'No se pudo contar las mediciones: ${error.toString()}',
      );
    }
  }

  @override
  Future<List<FieldEvaluation>> getEvaluations(int measurementId) async {
    try {
      final rows = await _databaseHelper.query(
        AppConstants.tableFieldEvaluations,
        where: '${AppConstants.columnMeasurementId} = ?',
        whereArgs: [measurementId],
        orderBy: '${AppConstants.columnId} ASC',
      );
      return rows
          .map(FieldEvaluationModel.fromMap)
          .map((model) => model.toEntity())
          .toList(growable: false);
    } on sqflite.DatabaseException catch (error) {
      throw DatabaseException(
        'No se pudieron obtener las evaluaciones de la medición '
        '$measurementId: ${error.toString()}',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Utilidades internas
  // ---------------------------------------------------------------------------

  /// Orden del historial: más reciente primero; `id` como desempate para que dos
  /// mediciones creadas en el mismo instante conserven un orden determinista.
  static const String _orderByCreatedAtDesc =
      '${AppConstants.columnCreatedAt} DESC, ${AppConstants.columnId} DESC';

  /// Carga una medición con sus hijos (puntos ordenados y evaluaciones).
  Future<Measurement?> _loadFullMeasurement(
    sqflite.DatabaseExecutor executor,
    int id,
  ) async {
    final rows = await executor.query(
      AppConstants.tableMeasurements,
      where: '${AppConstants.columnId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final pointRows = await executor.query(
      AppConstants.tableMeasurementPoints,
      where: '${AppConstants.columnMeasurementId} = ?',
      whereArgs: [id],
      orderBy: '${AppConstants.columnSeq} ASC',
    );
    final evaluationRows = await executor.query(
      AppConstants.tableFieldEvaluations,
      where: '${AppConstants.columnMeasurementId} = ?',
      whereArgs: [id],
      orderBy: '${AppConstants.columnId} ASC',
    );

    return MeasurementModel.fromMap(rows.first).toEntity(
      points: pointRows.map(GeoPointModel.fromMap).map((m) => m.toEntity()).toList(),
      evaluations: evaluationRows
          .map(FieldEvaluationModel.fromMap)
          .map((m) => m.toEntity())
          .toList(),
    );
  }

  /// Inserta los puntos reasignando `seq` según el orden de la lista.
  Future<void> _insertPoints(
    sqflite.Transaction txn,
    int measurementId,
    List<GeoPoint> points,
  ) async {
    if (points.isEmpty) return;

    final batch = txn.batch();
    for (var i = 0; i < points.length; i++) {
      final model = GeoPointModel.fromEntity(
        points[i].copyWith(measurementId: measurementId, seq: i),
      );
      batch.insert(
        AppConstants.tableMeasurementPoints,
        model.toMap(includeId: false),
      );
    }
    await batch.commit(noResult: true);
  }

  /// Inserta las evaluaciones asociándolas a la medición dueña.
  Future<void> _insertEvaluations(
    sqflite.Transaction txn,
    int measurementId,
    List<FieldEvaluation> evaluations,
  ) async {
    if (evaluations.isEmpty) return;

    final batch = txn.batch();
    for (final evaluation in evaluations) {
      final model = FieldEvaluationModel.fromEntity(
        evaluation.copyWith(measurementId: measurementId),
      );
      batch.insert(
        AppConstants.tableFieldEvaluations,
        model.toMap(includeId: false),
      );
    }
    await batch.commit(noResult: true);
  }

  /// Devuelve la precisión media a persistir: la indicada por el usuario o, si
  /// no la indicó, el promedio de la precisión de los puntos capturados.
  double? _resolveAvgAccuracy(Measurement measurement) {
    if (measurement.avgAccuracyM != null) return measurement.avgAccuracyM;
    if (measurement.points.isEmpty) return null;

    var total = 0.0;
    for (final point in measurement.points) {
      total += point.accuracy;
    }
    return total / measurement.points.length;
  }

  void _validateMeasurement(Measurement measurement) {
    if (measurement.name.trim().isEmpty) {
      throw const ValidationException('El nombre de la medición es obligatorio.');
    }
  }

  /// Valida los valores geográficos antes de tocar la base de datos, para
  /// reportar errores legibles en lugar de depender del texto de SQLite.
  void _validatePoints(List<GeoPoint> points) {
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final label = 'Punto ${i + 1}';

      if (point.latitude < -AppConstants.maxLatitude ||
          point.latitude > AppConstants.maxLatitude) {
        throw ValidationException(
          '$label: la latitud ${point.latitude} está fuera del rango '
          '[-90, 90].',
        );
      }
      if (point.longitude < -AppConstants.maxLongitude ||
          point.longitude > AppConstants.maxLongitude) {
        throw ValidationException(
          '$label: la longitud ${point.longitude} está fuera del rango '
          '[-180, 180].',
        );
      }
      if (point.accuracy < 0) {
        throw ValidationException(
          '$label: la precisión ${point.accuracy} no puede ser negativa.',
        );
      }
    }
  }

  /// Escapa los comodines de `LIKE` para que una búsqueda por nombre con `%`,
  /// `_` o `\` se comporte como texto literal.
  String _escapeLikePattern(String pattern) {
    return pattern
        .replaceAll('\\', '\\\\')
        .replaceAll('%', '\\%')
        .replaceAll('_', '\\_');
  }
}