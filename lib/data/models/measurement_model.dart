import '../../core/constants/app_constants.dart';
import '../../domain/entities/field_evaluation.dart';
import '../../domain/entities/geo_point.dart';
import '../../domain/entities/measurement.dart';
import '../../domain/entities/measurement_enums.dart';
import 'sqlite_values.dart';

/// Modelo de persistencia de una medición (`measurements`).
///
/// El mapeo de la cabecera es 1:1 con la tabla; los puntos y las evaluaciones
/// viven en tablas hijas y se convierten por separado mediante [toEntity].
class MeasurementModel {
  final int? id;
  final String name;
  final MeasurementType type;
  final double? areaM2;
  final double? perimeterM;
  final double? distanceM;
  final MeasurementMode mode;
  final MeasurementCategory? category;
  final String? notes;
  final double? avgAccuracyM;
  final DateTime createdAt;

  const MeasurementModel({
    this.id,
    required this.name,
    required this.type,
    this.areaM2,
    this.perimeterM,
    this.distanceM,
    required this.mode,
    this.category,
    this.notes,
    this.avgAccuracyM,
    required this.createdAt,
  });

  /// Construye el modelo a partir de una fila de `measurements`.
  ///
  /// Lanza [ArgumentError] si `type` o `mode` no corresponden a valores válidos
  /// de sus enumeraciones (dato corrupto o esquema desactualizado).
  factory MeasurementModel.fromMap(Map<String, Object?> map) {
    final rawType = SqliteValues.toStringOrNull(map[AppConstants.columnType]);
    final type = MeasurementType.fromValue(rawType);
    if (type == null) {
      throw ArgumentError(
        'Valor "$rawType" no válido para la columna '
        '"${AppConstants.columnType}" de ${AppConstants.tableMeasurements}.',
      );
    }

    final rawMode = SqliteValues.toStringOrNull(map[AppConstants.columnMode]);
    final mode = MeasurementMode.fromValue(rawMode);
    if (mode == null) {
      throw ArgumentError(
        'Valor "$rawMode" no válido para la columna '
        '"${AppConstants.columnMode}" de ${AppConstants.tableMeasurements}.',
      );
    }

    return MeasurementModel(
      id: SqliteValues.toInt(map[AppConstants.columnId]),
      name: SqliteValues.toStringOrNull(map[AppConstants.columnName]) ?? '',
      type: type,
      areaM2: SqliteValues.toDouble(map[AppConstants.columnAreaM2]),
      perimeterM: SqliteValues.toDouble(map[AppConstants.columnPerimeterM]),
      distanceM: SqliteValues.toDouble(map[AppConstants.columnDistanceM]),
      mode: mode,
      category: MeasurementCategory.fromValue(
        SqliteValues.toStringOrNull(map[AppConstants.columnCategory]),
      ),
      notes: SqliteValues.toStringOrNull(map[AppConstants.columnNotes]),
      avgAccuracyM: SqliteValues.toDouble(map[AppConstants.columnAvgAccuracyM]),
      createdAt: SqliteValues.dateTimeFromText(
        map[AppConstants.columnCreatedAt],
        column: AppConstants.columnCreatedAt,
      ),
    );
  }

  /// Construye el modelo desde la entidad de dominio.
  factory MeasurementModel.fromEntity(Measurement measurement) {
    return MeasurementModel(
      id: measurement.id,
      name: measurement.name,
      type: measurement.type,
      areaM2: measurement.areaM2,
      perimeterM: measurement.perimeterM,
      distanceM: measurement.distanceM,
      mode: measurement.mode,
      category: measurement.category,
      notes: measurement.notes,
      avgAccuracyM: measurement.avgAccuracyM,
      createdAt: measurement.createdAt,
    );
  }

  /// Convierte el modelo en la entidad de dominio.
  ///
  /// [points] y [evaluations] se entregan ya mapeados: son tablas hijas y no se
  /// incluyen en la cabecera.
  Measurement toEntity({
    List<GeoPoint> points = const <GeoPoint>[],
    List<FieldEvaluation> evaluations = const <FieldEvaluation>[],
  }) {
    return Measurement(
      id: id,
      name: name,
      type: type,
      areaM2: areaM2,
      perimeterM: perimeterM,
      distanceM: distanceM,
      mode: mode,
      category: category,
      notes: notes,
      avgAccuracyM: avgAccuracyM,
      createdAt: createdAt,
      points: points,
      evaluations: evaluations,
    );
  }

  /// Serializa el modelo a una fila de SQLite.
  ///
  /// [includeId] permite omitir la clave primaria (inserción con autogenerado).
  Map<String, Object?> toMap({bool includeId = true}) {
    return <String, Object?>{
      if (includeId && id != null) AppConstants.columnId: id,
      AppConstants.columnName: name,
      AppConstants.columnType: type.value,
      AppConstants.columnAreaM2: areaM2,
      AppConstants.columnPerimeterM: perimeterM,
      AppConstants.columnDistanceM: distanceM,
      AppConstants.columnMode: mode.value,
      AppConstants.columnCategory: category?.value,
      AppConstants.columnNotes: notes,
      AppConstants.columnAvgAccuracyM: avgAccuracyM,
      AppConstants.columnCreatedAt: SqliteValues.dateTimeToText(createdAt),
    };
  }

  /// Convierte una lista de filas en una lista de entidades de dominio.
  static List<Measurement> toEntities(List<Map<String, Object?>> rows) {
    return rows
        .map((row) => MeasurementModel.fromMap(row).toEntity())
        .toList(growable: false);
  }

  MeasurementModel copyWith({
    int? id,
    String? name,
    MeasurementType? type,
    double? areaM2,
    double? perimeterM,
    double? distanceM,
    MeasurementMode? mode,
    MeasurementCategory? category,
    String? notes,
    double? avgAccuracyM,
    DateTime? createdAt,
  }) {
    return MeasurementModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      areaM2: areaM2 ?? this.areaM2,
      perimeterM: perimeterM ?? this.perimeterM,
      distanceM: distanceM ?? this.distanceM,
      mode: mode ?? this.mode,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      avgAccuracyM: avgAccuracyM ?? this.avgAccuracyM,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'MeasurementModel(id: $id, name: $name, '
      'type: ${type.value}, areaM2: $areaM2, perimeterM: $perimeterM, '
      'distanceM: $distanceM, mode: ${mode.value}, category: ${category?.value}, '
      'notes: $notes, avgAccuracyM: $avgAccuracyM, createdAt: $createdAt)';
}
