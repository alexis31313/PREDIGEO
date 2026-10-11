import '../../core/constants/app_constants.dart';
import '../../domain/entities/geo_point.dart';
import 'sqlite_values.dart';

/// Modelo de persistencia de un punto GNSS (`measurement_points`).
///
/// Se encarga del mapeo entre la entidad de dominio [GeoPoint] y la fila de
/// SQLite, incluyendo la serialización de la marca de tiempo a ISO8601 UTC.
class GeoPointModel {
  final int? id;
  final int? measurementId;
  final int seq;
  final double latitude;
  final double longitude;
  final double altitude;
  final double accuracy;
  final DateTime timestamp;

  const GeoPointModel({
    this.id,
    this.measurementId,
    required this.seq,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracy,
    required this.timestamp,
  });

  /// Construye el modelo a partir de una fila de `measurement_points`.
  factory GeoPointModel.fromMap(Map<String, Object?> map) {
    return GeoPointModel(
      id: SqliteValues.toInt(map[AppConstants.columnId]),
      measurementId: SqliteValues.toInt(map[AppConstants.columnMeasurementId]),
      seq: SqliteValues.toInt(map[AppConstants.columnSeq]) ?? 0,
      latitude: SqliteValues.toDouble(map[AppConstants.columnLatitude]) ?? 0.0,
      longitude:
          SqliteValues.toDouble(map[AppConstants.columnLongitude]) ?? 0.0,
      altitude: SqliteValues.toDouble(map[AppConstants.columnAltitude]) ?? 0.0,
      accuracy: SqliteValues.toDouble(map[AppConstants.columnAccuracy]) ?? 0.0,
      timestamp: SqliteValues.dateTimeFromText(
        map[AppConstants.columnTimestamp],
        column: AppConstants.columnTimestamp,
      ),
    );
  }

  /// Construye el modelo desde la entidad de dominio.
  factory GeoPointModel.fromEntity(GeoPoint point) {
    return GeoPointModel(
      id: point.id,
      measurementId: point.measurementId,
      seq: point.seq,
      latitude: point.latitude,
      longitude: point.longitude,
      altitude: point.altitude,
      accuracy: point.accuracy,
      timestamp: point.timestamp,
    );
  }

  /// Convierte el modelo en la entidad de dominio.
  GeoPoint toEntity() {
    return GeoPoint(
      id: id,
      measurementId: measurementId,
      seq: seq,
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      accuracy: accuracy,
      timestamp: timestamp,
    );
  }

  /// Serializa el modelo a una fila de SQLite.
  ///
  /// [includeId] permite omitir la clave primaria (inserción con autogenerado)
  /// o incluirla (actualización o migración de datos existentes).
  Map<String, Object?> toMap({bool includeId = true}) {
    return <String, Object?>{
      if (includeId && id != null) AppConstants.columnId: id,
      AppConstants.columnMeasurementId: measurementId,
      AppConstants.columnSeq: seq,
      AppConstants.columnLatitude: latitude,
      AppConstants.columnLongitude: longitude,
      AppConstants.columnAltitude: altitude,
      AppConstants.columnAccuracy: accuracy,
      AppConstants.columnTimestamp: SqliteValues.dateTimeToText(timestamp),
    };
  }

  GeoPointModel copyWith({
    int? id,
    int? measurementId,
    int? seq,
    double? latitude,
    double? longitude,
    double? altitude,
    double? accuracy,
    DateTime? timestamp,
  }) {
    return GeoPointModel(
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
  String toString() => 'GeoPointModel(id: $id, measurementId: $measurementId, '
      'seq: $seq, lat: $latitude, lng: $longitude, alt: $altitude, '
      'acc: $accuracy, timestamp: $timestamp)';
}
