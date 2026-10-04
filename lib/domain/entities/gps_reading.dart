import 'package:geolocator/geolocator.dart';

/// Entidad inmutable que representa una lectura GPS del dispositivo.
class GpsReading {
  final double latitude;
  final double longitude;
  final double altitude;
  final double horizontalAccuracy;
  final double altitudeAccuracy;
  final double speed;
  final DateTime timestamp;

  const GpsReading({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.horizontalAccuracy,
    required this.altitudeAccuracy,
    required this.speed,
    required this.timestamp,
  });

  /// Constructor factory que crea una lectura GPS a partir de un objeto Position de geolocator.
  factory GpsReading.fromPosition(Position position) {
    return GpsReading(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      horizontalAccuracy: position.accuracy,
      altitudeAccuracy: position.altitudeAccuracy,
      speed: position.speed,
      timestamp: position.timestamp ?? DateTime.now(),
    );
  }

  /// Crea una copia de esta lectura con los campos especificados reemplazados.
  GpsReading copyWith({
    double? latitude,
    double? longitude,
    double? altitude,
    double? horizontalAccuracy,
    double? altitudeAccuracy,
    double? speed,
    DateTime? timestamp,
  }) {
    return GpsReading(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      horizontalAccuracy: horizontalAccuracy ?? this.horizontalAccuracy,
      altitudeAccuracy: altitudeAccuracy ?? this.altitudeAccuracy,
      speed: speed ?? this.speed,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'GpsReading(lat: $latitude, lng: $longitude, alt: $altitude, '
        'hAcc: $horizontalAccuracy, altAcc: $altitudeAccuracy, '
        'speed: $speed, time: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GpsReading &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.altitude == altitude &&
        other.horizontalAccuracy == horizontalAccuracy &&
        other.altitudeAccuracy == altitudeAccuracy &&
        other.speed == speed &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(
      latitude,
      longitude,
      altitude,
      horizontalAccuracy,
      altitudeAccuracy,
      speed,
      timestamp,
    );
  }
}
