/// Modelo de datos para coordenadas GPS.
/// Representa un punto geográfico capturado durante una medición.
class CoordinateModel {
  final int? id;
  final double latitude;
  final double longitude;
  final double altitude;
  final double accuracy;
  final DateTime timestamp;

  const CoordinateModel({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracy,
    required this.timestamp,
  });

  factory CoordinateModel.fromMap(Map<String, dynamic> map) {
    return CoordinateModel(
      id: map['id'] as int?,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      altitude: (map['altitude'] as num).toDouble(),
      accuracy: (map['accuracy'] as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'accuracy': accuracy,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  CoordinateModel copyWith({
    int? id,
    double? latitude,
    double? longitude,
    double? altitude,
    double? accuracy,
    DateTime? timestamp,
  }) {
    return CoordinateModel(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  factory CoordinateModel.fromJson(String source) {
    final map = Map<String, dynamic>.from(
      Uri.splitQueryString(source).map(
        (key, value) => MapEntry(key, value),
      ),
    );
    return CoordinateModel(
      id: int.tryParse(map['id'] ?? ''),
      latitude: double.parse(map['latitude']!),
      longitude: double.parse(map['longitude']!),
      altitude: double.parse(map['altitude']!),
      accuracy: double.parse(map['accuracy']!),
      timestamp: DateTime.parse(map['timestamp']!),
    );
  }

  String toJson() {
    return Uri.encodeQueryComponent('id') +
        '=' +
        (id?.toString() ?? '') +
        '&' +
        Uri.encodeQueryComponent('latitude') +
        '=' +
        latitude.toString() +
        '&' +
        Uri.encodeQueryComponent('longitude') +
        '=' +
        longitude.toString() +
        '&' +
        Uri.encodeQueryComponent('altitude') +
        '=' +
        altitude.toString() +
        '&' +
        Uri.encodeQueryComponent('accuracy') +
        '=' +
        accuracy.toString() +
        '&' +
        Uri.encodeQueryComponent('timestamp') +
        '=' +
        timestamp.toIso8601String();
  }

  @override
  String toString() {
    return 'CoordinateModel(id: $id, latitude: $latitude, longitude: $longitude, '
        'altitude: $altitude, accuracy: $accuracy, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoordinateModel &&
        other.id == id &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.altitude == altitude &&
        other.accuracy == accuracy &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(id, latitude, longitude, altitude, accuracy, timestamp);
  }
}
