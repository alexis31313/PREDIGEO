/// Entidad que representa una medición geoespacial con sus propiedades y resultados.
class Measurement {
  final int? id;
  final String name;
  final double area;
  final double perimeter;
  final double distance;
  final int coordinateCount;
  final String measurementType;
  final DateTime createdAt;
  final String? notes;

  const Measurement({
    this.id,
    required this.name,
    required this.area,
    required this.perimeter,
    required this.distance,
    required this.coordinateCount,
    required this.measurementType,
    required this.createdAt,
    this.notes,
  });

  Measurement copyWith({
    int? id,
    String? name,
    double? area,
    double? perimeter,
    double? distance,
    int? coordinateCount,
    String? measurementType,
    DateTime? createdAt,
    String? notes,
  }) {
    return Measurement(
      id: id ?? this.id,
      name: name ?? this.name,
      area: area ?? this.area,
      perimeter: perimeter ?? this.perimeter,
      distance: distance ?? this.distance,
      coordinateCount: coordinateCount ?? this.coordinateCount,
      measurementType: measurementType ?? this.measurementType,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'Measurement(id: $id, name: $name, area: $area, perimeter: $perimeter, distance: $distance, coords: $coordinateCount, type: $measurementType, created: $createdAt, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Measurement &&
        other.id == id &&
        other.name == name &&
        other.area == area &&
        other.perimeter == perimeter &&
        other.distance == distance &&
        other.coordinateCount == coordinateCount &&
        other.measurementType == measurementType &&
        other.createdAt == createdAt &&
        other.notes == notes;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        area.hashCode ^
        perimeter.hashCode ^
        distance.hashCode ^
        coordinateCount.hashCode ^
        measurementType.hashCode ^
        createdAt.hashCode ^
        notes.hashCode;
  }
}
