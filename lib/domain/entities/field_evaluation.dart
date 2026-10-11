import 'measurement_enums.dart';

/// Entidad inmutable que registra la comparación entre el valor calculado por
/// PrediGeo y un valor de referencia conocido del terreno.
///
/// Permite documentar el error absoluto, el error porcentual y el RMSE de una
/// medición en condiciones reales (rural abierto, rural con vegetación o urbano).
class FieldEvaluation {
  /// Identificador interno en `field_evaluations.id`. `null` antes de persistir.
  final int? id;

  /// Medición evaluada (relación 1..N con `measurements`).
  final int measurementId;

  /// Valor de referencia del terreno en metros cuadrados o en metros,
  /// según [referenceType].
  final double referenceValue;

  /// Procedencia del valor de referencia: agrimensura, agrimensor, plano
  /// catastral, punto de control GNSS conocido, etc.
  final String? referenceSource;

  /// Magnitud de la referencia: área o distancia.
  final ReferenceType referenceType;

  /// Condiciones del terreno al momento de medir (clima, cobertura vegetal,
  /// pendiente, hora del día, obstrucciones, etc.).
  final String? envConditions;

  const FieldEvaluation({
    this.id,
    required this.measurementId,
    required this.referenceValue,
    this.referenceSource,
    required this.referenceType,
    this.envConditions,
  });

  /// Devuelve una copia de la evaluación con los campos indicados modificados.
  FieldEvaluation copyWith({
    int? id,
    int? measurementId,
    double? referenceValue,
    String? referenceSource,
    ReferenceType? referenceType,
    String? envConditions,
  }) {
    return FieldEvaluation(
      id: id ?? this.id,
      measurementId: measurementId ?? this.measurementId,
      referenceValue: referenceValue ?? this.referenceValue,
      referenceSource: referenceSource ?? this.referenceSource,
      referenceType: referenceType ?? this.referenceType,
      envConditions: envConditions ?? this.envConditions,
    );
  }

  @override
  String toString() =>
      'FieldEvaluation(id: $id, measurementId: $measurementId, '
      'referenceValue: $referenceValue, referenceSource: $referenceSource, '
      'referenceType: ${referenceType.value}, envConditions: $envConditions)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FieldEvaluation &&
        other.id == id &&
        other.measurementId == measurementId &&
        other.referenceValue == referenceValue &&
        other.referenceSource == referenceSource &&
        other.referenceType == referenceType &&
        other.envConditions == envConditions;
  }

  @override
  int get hashCode => Object.hash(
        id,
        measurementId,
        referenceValue,
        referenceSource,
        referenceType,
        envConditions,
      );
}
