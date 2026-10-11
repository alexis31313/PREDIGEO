// Constructores de entidades de dominio reutilizados por las pruebas.

import 'package:predigeo/domain/entities/field_evaluation.dart';
import 'package:predigeo/domain/entities/geo_point.dart';
import 'package:predigeo/domain/entities/measurement.dart';
import 'package:predigeo/domain/entities/measurement_enums.dart';

/// Crea un punto GNSS de prueba en el área de Mocoa (Putumayo).
GeoPoint buildPoint({
  int seq = 0,
  double latitude = 1.15380,
  double longitude = -76.65100,
  double altitude = 430.0,
  double accuracy = 4.0,
  DateTime? timestamp,
}) {
  return GeoPoint(
    seq: seq,
    latitude: latitude,
    longitude: longitude,
    altitude: altitude,
    accuracy: accuracy,
    timestamp: timestamp ?? DateTime(2026, 3, 15, 14, 30, seq),
  );
}

/// Crea un polígono rectangular de cuatro puntos en metros (marcados como
/// grados decimales aproximados para Mocoa).
List<GeoPoint> buildPolygonPoints({double accuracy = 4.0}) {
  // ~11.1 m y ~11.0 m por paso de 0.00010° en la zona de Mocoa
  // const latStep = 0.00010;
  // const lonStep = 0.00010;
  final base = DateTime(2026, 3, 15, 14, 30);

  return <GeoPoint>[
    buildPoint(
        seq: 0,
        latitude: 1.15380,
        longitude: -76.65100,
        accuracy: accuracy,
        timestamp: base),
    buildPoint(
        seq: 1,
        latitude: 1.15390,
        longitude: -76.65100,
        accuracy: accuracy,
        timestamp: base.add(const Duration(seconds: 2))),
    buildPoint(
        seq: 2,
        latitude: 1.15390,
        longitude: -76.65090,
        accuracy: accuracy,
        timestamp: base.add(const Duration(seconds: 4))),
    buildPoint(
        seq: 3,
        latitude: 1.15380,
        longitude: -76.65090,
        accuracy: accuracy,
        timestamp: base.add(const Duration(seconds: 6))),
  ];
}

/// Crea una medición de prueba.
Measurement buildMeasurement({
  int? id,
  String name = 'Lote de prueba',
  MeasurementType type = MeasurementType.area,
  MeasurementMode mode = MeasurementMode.offline,
  MeasurementCategory? category = MeasurementCategory.ruralOpen,
  double? areaM2 = 1200.0,
  double? perimeterM = 140.0,
  double? distanceM,
  double? avgAccuracyM,
  String? notes = 'Medición de campo',
  DateTime? createdAt,
  List<GeoPoint>? points,
  List<FieldEvaluation>? evaluations,
}) {
  return Measurement(
    id: id,
    name: name,
    type: type,
    areaM2: type == MeasurementType.area ? areaM2 : null,
    perimeterM: type == MeasurementType.area ? perimeterM : null,
    distanceM: distanceM ?? (type == MeasurementType.path ? 850.0 : null),
    mode: mode,
    category: category,
    notes: notes,
    avgAccuracyM: avgAccuracyM,
    createdAt: createdAt ?? DateTime(2026, 3, 15, 14, 30),
    points: points ?? const <GeoPoint>[],
    evaluations: evaluations ?? const <FieldEvaluation>[],
  );
}

/// Crea una evaluación de campo de prueba.
FieldEvaluation buildEvaluation({
  int? id,
  int measurementId = 1,
  double referenceValue = 1250.0,
  String? referenceSource = 'Agrimensura',
  ReferenceType referenceType = ReferenceType.area,
  String? envConditions = 'Cielo despejado, sin vegetación densa',
}) {
  return FieldEvaluation(
    id: id,
    measurementId: measurementId,
    referenceValue: referenceValue,
    referenceSource: referenceSource,
    referenceType: referenceType,
    envConditions: envConditions,
  );
}
