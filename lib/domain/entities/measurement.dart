import 'field_evaluation.dart';
import 'geo_point.dart';
import 'measurement_enums.dart';

/// Entidad inmutable que representa una medición geoespacial completa.
///
/// Una medición agrupa:
/// - los datos descriptivos (nombre, tipo, modalidad, categoría de terreno);
/// - los resultados calculados (área, perímetro, distancia);
/// - los puntos GNSS capturados ([points]);
/// - las evaluaciones de campo associate ([evaluations]).
///
/// La entidad se considera "cargada" cuando trae los puntos y las evaluaciones;
/// las consultas de listado devolven solo la cabecera y dejan ambas listas vacías.
class Measurement {
  /// Identificador interno en `measurements.id`. Es `null` antes de persistir.
  final int? id;

  /// Nombre descriptivo de la medición. Nunca puede estar vacío.
  final String name;

  /// Tipo de medición: polígono de área o trayecto recorrido.
  final MeasurementType type;

  /// Área del polígono en metros cuadrados. `null` para mediciones de trayecto.
  final double? areaM2;

  /// Perímetro del polígono en metros. `null` para mediciones de trayecto.
  final double? perimeterM;

  /// Distancia recorrida en metros. `null` para mediciones de área sin trayecto.
  final double? distanceM;

  /// Modalidad de captura: con conexión (`online`) u offline (`offline`).
  final MeasurementMode mode;

  /// Categoría del terreno. `null` cuando la medición no fue clasificada.
  final MeasurementCategory? category;

  /// Observaciones del usuario.
  final String? notes;

  /// Precisión horizontal media de los puntos, en metros.
  /// El repositorio la calcula a partir de [points] cuando no se provee.
  final double? avgAccuracyM;

  /// Fecha y hora de creación de la medición.
  final DateTime createdAt;

  /// Puntos GNSS en orden de captura. Lista inmutable.
  final List<GeoPoint> points;

  /// Evaluaciones de campo asociadas. Lista inmutable.
  final List<FieldEvaluation> evaluations;

  Measurement({
    this.id,
    required this.name,
    required this.type,
    this.areaM2,
    this.perimeterM,
    this.distanceM,
    required this.mode,
    this.category,
    this.notes,
    this.avgAccuracyM,
    required this.createdAt,
    List<GeoPoint> points = const <GeoPoint>[],
    List<FieldEvaluation> evaluations = const <FieldEvaluation>[],
  })  : points = List<GeoPoint>.unmodifiable(points),
        evaluations = List<FieldEvaluation>.unmodifiable(evaluations);

  /// `true` cuando la medición representa un polígono de área.
  bool get isArea => type == MeasurementType.area;

  /// `true` cuando la medición representa un trayecto.
  bool get isPath => type == MeasurementType.path;

  /// `true` cuando la medición fue capturada sin conexión a internet.
  bool get isOffline => mode == MeasurementMode.offline;

  /// Cantidad de puntos capturados.
  int get pointCount => points.length;

  /// Altitud mínima de los puntos, en metros. `null` si no hay puntos.
  double? get minAltitude {
    if (points.isEmpty) return null;
    var min = points.first.altitude;
    for (final point in points) {
      if (point.altitude < min) min = point.altitude;
    }
    return min;
  }

  /// Altitud máxima de los puntos, en metros. `null` si no hay puntos.
  double? get maxAltitude {
    if (points.isEmpty) return null;
    var max = points.first.altitude;
    for (final point in points) {
      if (point.altitude > max) max = point.altitude;
    }
    return max;
  }

  /// Desnivel entre el punto más alto y el más bajo. `null` si no hay puntos.
  double? get altitudeRange {
    final min = minAltitude;
    final max = maxAltitude;
    if (min == null || max == null) return null;
    return max - min;
  }

  /// Devuelve una copia de la medición con los campos indicados modificados.
  ///
  /// `points` y `evaluations` se reemplazan por completo cuando se pasan;
  /// en caso contrario se conservan las listas actuales.
  Measurement copyWith({
    int? id,
    String? name,
    MeasurementType? type,
    double? areaM2,
    double? perimeterM,
    double? distanceM,
    MeasurementMode? mode,
    MeasurementCategory? category,
    String? notes,
    double? avgAccuracyM,
    DateTime? createdAt,
    List<GeoPoint>? points,
    List<FieldEvaluation>? evaluations,
  }) {
    return Measurement(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      areaM2: areaM2 ?? this.areaM2,
      perimeterM: perimeterM ?? this.perimeterM,
      distanceM: distanceM ?? this.distanceM,
      mode: mode ?? this.mode,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      avgAccuracyM: avgAccuracyM ?? this.avgAccuracyM,
      createdAt: createdAt ?? this.createdAt,
      points: points ?? this.points,
      evaluations: evaluations ?? this.evaluations,
    );
  }

  @override
  String toString() => 'Measurement(id: $id, name: $name, type: ${type.value}, '
      'areaM2: $areaM2, perimeterM: $perimeterM, distanceM: $distanceM, '
      'mode: ${mode.value}, category: ${category?.value}, notes: $notes, '
      'avgAccuracyM: $avgAccuracyM, createdAt: $createdAt, points: ${points.length}, '
      'evaluations: ${evaluations.length})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Measurement &&
        other.id == id &&
        other.name == name &&
        other.type == type &&
        other.areaM2 == areaM2 &&
        other.perimeterM == perimeterM &&
        other.distanceM == distanceM &&
        other.mode == mode &&
        other.category == category &&
        other.notes == notes &&
        other.avgAccuracyM == avgAccuracyM &&
        other.createdAt == createdAt &&
        listEquals(other.points, points) &&
        listEquals(other.evaluations, evaluations);
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        type,
        areaM2,
        perimeterM,
        distanceM,
        mode,
        category,
        notes,
        avgAccuracyM,
        createdAt,
        Object.hashAll(points),
        Object.hashAll(evaluations),
      );
}

/// Compara dos listas por contenido usando la igualdad de cada elemento.
/// Evita depender de `package:flutter/foundation.dart` en la capa de dominio.
bool listEquals<E>(List<E> a, List<E> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}