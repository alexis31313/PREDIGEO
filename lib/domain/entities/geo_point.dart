/// Entidad inmutable que representa un punto geográfico (GNSS) capturado durante
/// una medición.
///
/// Datum de referencia: MAGNA-SIRGAS. Las coordenadas se almacenan en grados
/// decimales (WGS84 / MAGNA-SIRGAS), la altitud en metros sobre el elipsoide y
/// la precisión horizontal reportada por el receptor en metros.
class GeoPoint {
  /// Identificador interno en `measurement_points.id`. Es `null` mientras el
  /// punto todavía no ha sido persistido.
  final int? id;

  /// Medición propietaria. Es `null` mientras el punto no está persistido.
  final int? measurementId;

  /// Orden del punto dentro de la medición (0, 1, 2, ...). El orden define la
  /// secuencia de captura y, en mediciones de área, el sentido del polígono.
  final int seq;

  /// Latitud en grados decimales, rango válido [-90, 90].
  final double latitude;

  /// Longitud en grados decimales, rango válido [-180, 180].
  final double longitude;

  /// Altitud en metros respecto al elipsoide de referencia.
  final double altitude;

  /// Precisión horizontal reportada por el receptor GNSS, en metros.
  final double accuracy;

  /// Marca de tiempo de captura (instante del fix).
  final DateTime timestamp;

  const GeoPoint({
    this.id,
    this.measurementId,
    required this.seq,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracy,
    required this.timestamp,
  });

  /// Devuelve una copia del punto con los campos indicados modificados.
  GeoPoint copyWith({
    int? id,
    int? measurementId,
    int? seq,
    double? latitude,
    double? longitude,
    double? altitude,
    double? accuracy,
    DateTime? timestamp,
  }) {
    return GeoPoint(
      id: id ?? this.id,
      measurementId: measurementId ?? this.measurementId,
      seq: seq ?? this.seq,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() => 'GeoPoint(id: $id, measurementId: $measurementId, seq: $seq, '
      'lat: $latitude, lng: $longitude, alt: $altitude, acc: $accuracy, ts: $timestamp)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GeoPoint &&
        other.id == id &&
        other.measurementId == measurementId &&
        other.seq == seq &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.altitude == altitude &&
        other.accuracy == accuracy &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => Object.hash(
        id,
        measurementId,
        seq,
        latitude,
        longitude,
        altitude,
        accuracy,
        timestamp,
      );
}

/// Compara dos puntos por su contenido geográfico, ignorando los metadatos de
/// persistencia (`id`, `measurementId`) y la marca de tiempo.
///
/// Útil en pruebas unitarias para verificar que un punto totalmente reconstruido
/// desde SQLite es equivalente al original.
bool sameGeoPosition(
  GeoPoint a,
  GeoPoint b, {
  double tolerance = 1e-9,
}) {
  return (a.latitude - b.latitude).abs() <= tolerance &&
      (a.longitude - b.longitude).abs() <= tolerance &&
      (a.altitude - b.altitude).abs() <= tolerance;
}