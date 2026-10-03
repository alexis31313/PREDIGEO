/// Modelo de datos para mediciones geográficas.
/// Representa una medición completa con sus datos calculados y metadatos.
class MeasurementModel {
  final int? id;
  final String name;
  final double area;
  final double perimeter;
  final double distance;
  final int coordinateCount;
  final String measurementType;
  final DateTime createdAt;
  final String? notes;

  const MeasurementModel({
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

  factory MeasurementModel.fromMap(Map<String, dynamic> map) {
    return MeasurementModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      area: (map['area'] as num).toDouble(),
      perimeter: (map['perimeter'] as num).toDouble(),
      distance: (map['distance'] as num).toDouble(),
      coordinateCount: map['coordinate_count'] as int,
      measurementType: map['measurement_type'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'area': area,
      'perimeter': perimeter,
      'distance': distance,
      'coordinate_count': coordinateCount,
      'measurement_type': measurementType,
      'created_at': createdAt.millisecondsSinceEpoch,
      'notes': notes,
    };
  }

  MeasurementModel copyWith({
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
    return MeasurementModel(
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

  factory MeasurementModel.fromJson(String source) {
    final map = Map<String, dynamic>.from(
      Uri.splitQueryString(source).map(
        (key, value) => MapEntry(key, value),
      ),
    );
    return MeasurementModel(
      id: int.tryParse(map['id'] ?? ''),
      name: map['name']!,
      area: double.parse(map['area']!),
      perimeter: double.parse(map['perimeter']!),
      distance: double.parse(map['distance']!),
      coordinateCount: int.parse(map['coordinate_count']!),
      measurementType: map['measurement_type']!,
      createdAt: DateTime.parse(map['created_at']!),
      notes: map['notes'],
    );
  }

  String toJson() {
    return Uri.encodeQueryComponent('id') +
        '=' +
        (id?.toString() ?? '') +
        '&' +
        Uri.encodeQueryComponent('name') +
        '=' +
        Uri.encodeComponent(name) +
        '&' +
        Uri.encodeQueryComponent('area') +
        '=' +
        area.toString() +
        '&' +
        Uri.encodeQueryComponent('perimeter') +
        '=' +
        perimeter.toString() +
        '&' +
        Uri.encodeQueryComponent('distance') +
        '=' +
        distance.toString() +
        '&' +
        Uri.encodeQueryComponent('coordinate_count') +
        '=' +
        coordinateCount.toString() +
        '&' +
        Uri.encodeQueryComponent('measurement_type') +
        '=' +
        Uri.encodeComponent(measurementType) +
        '&' +
        Uri.encodeQueryComponent('created_at') +
        '=' +
        createdAt.toIso8601String() +
        '&' +
        Uri.encodeQueryComponent('notes') +
        '=' +
        (notes != null ? Uri.encodeComponent(notes!) : '');
  }

  @override
  String toString() {
    return 'MeasurementModel(id: $id, name: $name, area: $area, '
        'perimeter: $perimeter, distance: $distance, '
        'coordinateCount: $coordinateCount, measurementType: $measurementType, '
        'createdAt: $createdAt, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MeasurementModel &&
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
    return Object.hash(
      id,
      name,
      area,
      perimeter,
      distance,
      coordinateCount,
      measurementType,
      createdAt,
      notes,
    );
  }
}
