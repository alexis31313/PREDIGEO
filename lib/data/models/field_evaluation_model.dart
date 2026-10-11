import '../../core/constants/app_constants.dart';
import '../../domain/entities/field_evaluation.dart';
import '../../domain/entities/measurement_enums.dart';
import 'sqlite_values.dart';

/// Modelo de persistencia de una evaluación de campo (`field_evaluations`).
class FieldEvaluationModel {
  final int? id;
  final int measurementId;
  final double referenceValue;
  final String? referenceSource;
  final ReferenceType referenceType;
  final String? envConditions;

  const FieldEvaluationModel({
    this.id,
    required this.measurementId,
    required this.referenceValue,
    this.referenceSource,
    required this.referenceType,
    this.envConditions,
  });

  /// Construye el modelo a partir de una fila de `field_evaluations`.
  ///
  /// Lanza [ArgumentError] si `reference_type` no corresponde a ningún valor
  /// válido del enum [ReferenceType] (dato corrupto o esquema desactualizado).
  factory FieldEvaluationModel.fromMap(Map<String, Object?> map) {
    final rawType = SqliteValues.toStringOrNull(
      map[AppConstants.columnReferenceType],
    );
    final referenceType = ReferenceType.fromValue(rawType);
    if (referenceType == null) {
      throw ArgumentError(
        'Valor "$rawType" no válido para la columna '
        '"${AppConstants.columnReferenceType}" de '
        '${AppConstants.tableFieldEvaluations}.',
      );
    }

    return FieldEvaluationModel(
      id: SqliteValues.toInt(map[AppConstants.columnId]),
      measurementId:
          SqliteValues.toInt(map[AppConstants.columnMeasurementId]) ?? 0,
      referenceValue:
          SqliteValues.toDouble(map[AppConstants.columnReferenceValue]) ?? 0.0,
      referenceSource:
          SqliteValues.toStringOrNull(map[AppConstants.columnReferenceSource]),
      referenceType: referenceType,
      envConditions:
          SqliteValues.toStringOrNull(map[AppConstants.columnEnvConditions]),
    );
  }

  /// Construye el modelo desde la entidad de dominio.
  factory FieldEvaluationModel.fromEntity(FieldEvaluation evaluation) {
    return FieldEvaluationModel(
      id: evaluation.id,
      measurementId: evaluation.measurementId,
      referenceValue: evaluation.referenceValue,
      referenceSource: evaluation.referenceSource,
      referenceType: evaluation.referenceType,
      envConditions: evaluation.envConditions,
    );
  }

  /// Convierte el modelo en la entidad de dominio.
  FieldEvaluation toEntity() {
    return FieldEvaluation(
      id: id,
      measurementId: measurementId,
      referenceValue: referenceValue,
      referenceSource: referenceSource,
      referenceType: referenceType,
      envConditions: envConditions,
    );
  }

  /// Serializa el modelo a una fila de SQLite.
  Map<String, Object?> toMap({bool includeId = true}) {
    return <String, Object?>{
      if (includeId && id != null) AppConstants.columnId: id,
      AppConstants.columnMeasurementId: measurementId,
      AppConstants.columnReferenceValue: referenceValue,
      AppConstants.columnReferenceSource: referenceSource,
      AppConstants.columnReferenceType: referenceType.value,
      AppConstants.columnEnvConditions: envConditions,
    };
  }

  FieldEvaluationModel copyWith({
    int? id,
    int? measurementId,
    double? referenceValue,
    String? referenceSource,
    ReferenceType? referenceType,
    String? envConditions,
  }) {
    return FieldEvaluationModel(
      id: id ?? this.id,
      measurementId: measurementId ?? this.measurementId,
      referenceValue: referenceValue ?? this.referenceValue,
      referenceSource: referenceSource ?? this.referenceSource,
      referenceType: referenceType ?? this.referenceType,
      envConditions: envConditions ?? this.envConditions,
    );
  }

  @override
  String toString() => 'FieldEvaluationModel(id: $id, '
      'measurementId: $measurementId, referenceValue: $referenceValue, '
      'referenceSource: $referenceSource, '
      'referenceType: ${referenceType.value}, envConditions: $envConditions)';
}
