/// Entidad que representa una sesión de medición vinculando una medición con sus coordenadas.
class MeasurementSession {
  final int? id;
  final int measurementId;
  final int coordinateId;
  final int orderIndex;

  const MeasurementSession({
    this.id,
    required this.measurementId,
    required this.coordinateId,
    required this.orderIndex,
  });

  MeasurementSession copyWith({
    int? id,
    int? measurementId,
    int? coordinateId,
    int? orderIndex,
  }) {
    return MeasurementSession(
      id: id ?? this.id,
      measurementId: measurementId ?? this.measurementId,
      coordinateId: coordinateId ?? this.coordinateId,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  @override
  String toString() {
    return 'MeasurementSession(id: $id, measurementId: $measurementId, coordinateId: $coordinateId, order: $orderIndex)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MeasurementSession &&
        other.id == id &&
        other.measurementId == measurementId &&
        other.coordinateId == coordinateId &&
        other.orderIndex == orderIndex;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        measurementId.hashCode ^
        coordinateId.hashCode ^
        orderIndex.hashCode;
  }
}
