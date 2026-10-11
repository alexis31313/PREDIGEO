// Estado y lógica de la sesión de medición en curso.
//
// Mantiene en memoria los puntos capturados, el tipo de medición, la categoría
// de terreno y los campos descriptivos, y expone las métricas derivadas (área,
// perímetro, distancia, precisión media y estadísticas de relieve).
//
// Es independiente de la persistencia: la pantalla de medición usa este estado
// para construir una entidad [Measurement] y guardarla a través del repositorio.

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/geo_point.dart';
import '../../domain/entities/measurement_enums.dart';
import '../../domain/usecases/geo/area_calculator.dart';
import '../../domain/usecases/geo/distance_calculator.dart';
import '../../domain/usecases/geo/elevation_stats.dart';
import '../../domain/usecases/signal_processing/captured_point.dart';

/// Estado inmutable de la medición en curso.
@immutable
class MeasurementSessionState {
  /// Tipo de medición: polígono de área o trayecto.
  final MeasurementType type;

  /// Puntos ya capturados, en orden de captura (el `seq` es su índice).
  final List<GeoPoint> points;

  /// Categoría de terreno seleccionada. `null` si aún no se clasificó.
  final MeasurementCategory? category;

  /// Nombre descriptivo de la medición.
  final String name;

  /// Observaciones del usuario.
  final String notes;

  /// `true` mientras hay una captura de punto en curso.
  final bool isCapturing;

  /// Progreso de la captura en curso, de 0.0 a 1.0.
  final double captureProgress;

  /// Mensaje de error de la última operación (captura o guardado).
  final String? errorMessage;

  const MeasurementSessionState({
    this.type = MeasurementType.area,
    this.points = const <GeoPoint>[],
    this.category,
    this.name = '',
    this.notes = '',
    this.isCapturing = false,
    this.captureProgress = 0.0,
    this.errorMessage,
  });

  /// Cantidad de puntos capturados.
  int get pointCount => points.length;

  /// `true` cuando hay puntos suficientes para el tipo seleccionado: al menos
  /// 3 para un área (polígono) y al menos 2 para un trayecto.
  bool get hasEnoughPoints {
    if (type == MeasurementType.area) {
      return points.length >= 3;
    }
    return points.length >= 2;
  }

  /// Área calculada en metros cuadrados, o `null` si no aplica.
  double? get areaM2 {
    if (type != MeasurementType.area || points.length < 3) return null;
    return AreaCalculator.fromGeoPoints(points);
  }

  /// Perímetro calculado en metros, o `null` si no aplica.
  double? get perimeterM {
    if (type != MeasurementType.area || points.length < 2) return null;
    return DistanceCalculator.perimeter(points);
  }

  /// Distancia recorrida en metros, o `null` si no aplica.
  double? get distanceM {
    if (type != MeasurementType.path || points.length < 2) return null;
    return DistanceCalculator.pathLength(points);
  }

  /// Precisión horizontal media de los puntos, en metros. `0` sin puntos.
  double get avgAccuracyM {
    if (points.isEmpty) return 0.0;
    final sum = points.fold<double>(0, (acc, p) => acc + p.accuracy);
    return sum / points.length;
  }

  /// Estadísticas de relieve (altitud) de los puntos capturados.
  ElevationStats get elevationStats => ElevationStats.fromPoints(points);

  /// `true` cuando la medición puede guardarse: nombre no vacío, sin captura
  /// en curso y con puntos suficientes.
  bool get canSave => !isCapturing && name.trim().isNotEmpty && hasEnoughPoints;

  MeasurementSessionState copyWith({
    MeasurementType? type,
    List<GeoPoint>? points,
    MeasurementCategory? category,
    String? name,
    String? notes,
    bool? isCapturing,
    double? captureProgress,
    String? errorMessage,
    bool clearCategory = false,
    bool clearError = false,
  }) {
    return MeasurementSessionState(
      type: type ?? this.type,
      points: points ?? this.points,
      category: clearCategory ? null : (category ?? this.category),
      name: name ?? this.name,
      notes: notes ?? this.notes,
      isCapturing: isCapturing ?? this.isCapturing,
      captureProgress: captureProgress ?? this.captureProgress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class MeasurementSessionNotifier extends Notifier<MeasurementSessionState> {
  @override
  MeasurementSessionState build() => const MeasurementSessionState();

  void setType(MeasurementType type) {
    if (state.type == type) return;
    // Cambiar de tipo altera las métricas; se conservan los puntos capturados.
    state = state.copyWith(type: type, clearError: true);
  }

  void setCategory(MeasurementCategory? category) {
    state = category == null
        ? state.copyWith(clearCategory: true)
        : state.copyWith(category: category);
  }

  void setName(String name) => state = state.copyWith(name: name);

  void setNotes(String notes) => state = state.copyWith(notes: notes);

  /// Marca el inicio de una captura de punto.
  void startCapture() {
    state = state.copyWith(
      isCapturing: true,
      captureProgress: 0.0,
      clearError: true,
    );
  }

  /// Actualiza el progreso de la captura en curso (0.0 a 1.0).
  void updateCaptureProgress(double progress) {
    if (!state.isCapturing) return;
    state = state.copyWith(captureProgress: progress.clamp(0.0, 1.0));
  }

  /// Añade un punto capturado al final de la lista y cierra la captura.
  void addCapturedPoint(CapturedPoint captured) {
    final point = GeoPoint(
      seq: state.points.length,
      latitude: captured.latitude,
      longitude: captured.longitude,
      altitude: captured.altitude,
      accuracy: captured.estimatedAccuracy,
      timestamp: captured.timestamp,
    );
    state = state.copyWith(
      points: [...state.points, point],
      isCapturing: false,
      captureProgress: 0.0,
      clearError: true,
    );
  }

  /// Cancela la captura en curso guardando un mensaje de error.
  void failCapture(String message) {
    state = state.copyWith(
      isCapturing: false,
      captureProgress: 0.0,
      errorMessage: message,
    );
  }

  /// Elimina el último punto capturado y renumera la secuencia.
  void removeLastPoint() {
    if (state.points.isEmpty) return;
    final remaining = state.points.sublist(0, state.points.length - 1);
    final resequenced = <GeoPoint>[
      for (var i = 0; i < remaining.length; i++) remaining[i].copyWith(seq: i),
    ];
    state = state.copyWith(points: resequenced, clearError: true);
  }

  /// Descarta todos los puntos pero conserva el tipo y la categoría elegidos.
  void clearPoints() {
    state = state.copyWith(
      points: const <GeoPoint>[],
      isCapturing: false,
      captureProgress: 0.0,
      clearError: true,
    );
  }

  /// Restablece la sesión por completo.
  void reset() => state = const MeasurementSessionState();
}

final measurementSessionProvider =
    NotifierProvider<MeasurementSessionNotifier, MeasurementSessionState>(
  MeasurementSessionNotifier.new,
);
