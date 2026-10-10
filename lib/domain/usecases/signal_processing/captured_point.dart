/// Entidad inmutable que representa un punto capturado y procesado.
/// Contiene las coordenadas promediadas, la precisión estimada,
/// el número de muestras utilizadas y la fecha de captura.
class CapturedPoint {
  final double latitude;
  final double longitude;
  final double altitude;
  final double estimatedAccuracy;
  final int sampleCount;
  final DateTime timestamp;

  const CapturedPoint({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.estimatedAccuracy,
    required this.sampleCount,
    required this.timestamp,
  });

  /// Crea una copia de este punto con los campos especificados reemplazados.
  CapturedPoint copyWith({
    double? latitude,
    double? longitude,
    double? altitude,
    double? estimatedAccuracy,
    int? sampleCount,
    DateTime? timestamp,
  }) {
    return CapturedPoint(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      estimatedAccuracy: estimatedAccuracy ?? this.estimatedAccuracy,
      sampleCount: sampleCount ?? this.sampleCount,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'CapturedPoint(lat: $latitude, lng: $longitude, alt: $altitude, '
        'accuracy: $estimatedAccuracy, samples: $sampleCount, '
        'timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CapturedPoint &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.altitude == altitude &&
        other.estimatedAccuracy == estimatedAccuracy &&
        other.sampleCount == sampleCount &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(
      latitude,
      longitude,
      altitude,
      estimatedAccuracy,
      sampleCount,
      timestamp,
    );
  }
}
