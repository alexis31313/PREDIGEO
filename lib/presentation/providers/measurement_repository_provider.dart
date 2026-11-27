// Proveedores de Riverpod para la capa de persistencia local:
// acceso a la base de datos, repositorio de mediciones y consultas derivadas.

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/database_helper.dart';
import '../../data/datasources/interior_points_store.dart';
import '../../data/repositories/sqlite_measurement_repository.dart';
import '../../domain/entities/field_evaluation.dart';
import '../../domain/entities/geo_point.dart';
import '../../domain/entities/measurement.dart';
import '../../domain/entities/measurement_enums.dart';
import '../../domain/repositories/measurement_repository.dart';

/// Acceso a la base de datos local. La conexión se abre de forma perezosa la
/// primera vez que el repositorio la utiliza.
final databaseHelperProvider = Provider<DatabaseHelper>(
  (ref) => DatabaseHelper.instance,
);

/// Repositorio de mediciones. Es la única vía de la aplicación hacia SQLite:
/// la interfaz de usuario nunca conversa con la base de datos directamente.
///
/// Se puede sobrescribir en una `ProviderScope` de pruebas con
/// `overrideWithValue(SqliteMeasurementRepository(DatabaseHelper.forTesting(...)))`.
final measurementRepositoryProvider = Provider<MeasurementRepository>(
  (ref) => SqliteMeasurementRepository(ref.watch(databaseHelperProvider)),
);

/// Almacén de los puntos interiores (muestreo 3D) de cada medición.
final interiorPointsStoreProvider = Provider<InteriorPointsStore>(
  (ref) => InteriorPointsStore(),
);

/// Puntos interiores guardados de una medición. Si no se pueden leer, se
/// devuelve una lista vacía (la vista 3D usa entonces solo el contorno).
final interiorPointsProvider =
    FutureProvider.family<List<GeoPoint>, int>((ref, measurementId) async {
  try {
    return await ref.watch(interiorPointsStoreProvider).load(measurementId);
  } catch (_) {
    return const <GeoPoint>[];
  }
});

/// Historial completo, ordenado de más reciente a más antiguo.
/// La cabecera de la medición se recarga cuando el historial cambia
/// (invalidado por `ref.invalidate(measurementHistoryProvider)`).
final measurementHistoryProvider = FutureProvider<List<Measurement>>(
  (ref) => ref.watch(measurementRepositoryProvider).getAll(),
);

/// Detalle de una medición (cabecera + puntos + evaluaciones).
final measurementDetailProvider = FutureProvider.family<Measurement?, int>(
  (ref, id) => ref.watch(measurementRepositoryProvider).getById(id),
);

/// Búsqueda de mediciones por nombre. Un término vacío devuelve todo el
/// historial, por lo que la interfaz puede usar el mismo proveedor siempre.
final measurementSearchProvider =
    FutureProvider.family<List<Measurement>, String>(
  (ref, term) => ref.watch(measurementRepositoryProvider).search(term),
);

/// Filtros activos del historial por tipo, modalidad de captura y categoría de
/// terreno.
@immutable
class MeasurementFilter {
  final MeasurementType? type;
  final MeasurementMode? mode;
  final MeasurementCategory? category;
  final bool onlyUncategorized;

  const MeasurementFilter({
    this.type,
    this.mode,
    this.category,
    this.onlyUncategorized = false,
  });

  /// `true` cuando hay al menos un criterio activo.
  bool get hasActiveFilters =>
      type != null || mode != null || category != null || onlyUncategorized;

  MeasurementFilter copyWith({
    MeasurementType? type,
    MeasurementMode? mode,
    MeasurementCategory? category,
    bool? onlyUncategorized,
    bool clearType = false,
    bool clearMode = false,
    bool clearCategory = false,
  }) {
    return MeasurementFilter(
      type: clearType ? null : (type ?? this.type),
      mode: clearMode ? null : (mode ?? this.mode),
      category: clearCategory ? null : (category ?? this.category),
      onlyUncategorized: onlyUncategorized ?? this.onlyUncategorized,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MeasurementFilter &&
        other.type == type &&
        other.mode == mode &&
        other.category == category &&
        other.onlyUncategorized == onlyUncategorized;
  }

  @override
  int get hashCode => Object.hash(type, mode, category, onlyUncategorized);
}

class MeasurementFilterNotifier extends Notifier<MeasurementFilter> {
  @override
  MeasurementFilter build() => const MeasurementFilter();

  void setType(MeasurementType? type) => state = type == null
      ? state.copyWith(clearType: true)
      : state.copyWith(type: type);

  void setMode(MeasurementMode? mode) => state = mode == null
      ? state.copyWith(clearMode: true)
      : state.copyWith(mode: mode);

  void setCategory(MeasurementCategory? category) => state = category == null
      ? state.copyWith(clearCategory: true)
      : state.copyWith(category: category);

  void setOnlyUncategorized(bool value) =>
      state = state.copyWith(onlyUncategorized: value);

  void clearAll() => state = const MeasurementFilter();
}

final measurementFilterProvider =
    NotifierProvider<MeasurementFilterNotifier, MeasurementFilter>(
  MeasurementFilterNotifier.new,
);

/// Historial filtrado según [measurementFilterProvider].
final filteredMeasurementsProvider = FutureProvider<List<Measurement>>((ref) {
  final filter = ref.watch(measurementFilterProvider);
  return ref.watch(measurementRepositoryProvider).filter(
        type: filter.type,
        mode: filter.mode,
        category: filter.category,
        onlyUncategorized: filter.onlyUncategorized,
      );
});

/// Mediciones del historial con sus evaluaciones de campo ya cargadas.
///
/// La pantalla de evaluación necesita tanto los resultados de la medición
/// (área/distancia) como las evaluaciones asociadas, por lo que agrega ambas
/// en una sola fuente de datos.
final measurementsWithEvaluationsProvider = FutureProvider<List<Measurement>>(
  (ref) async {
    final repository = ref.watch(measurementRepositoryProvider);
    final measurements = await repository.getAll();

    final result = <Measurement>[];
    for (final measurement in measurements) {
      final evaluations = measurement.id == null
          ? const <FieldEvaluation>[]
          : await repository.getEvaluations(measurement.id!);
      result.add(measurement.copyWith(evaluations: evaluations));
    }
    return result;
  },
);

/// Evaluaciones de campo de una medición.
final fieldEvaluationsProvider =
    FutureProvider.family<List<FieldEvaluation>, int>(
  (ref, measurementId) =>
      ref.watch(measurementRepositoryProvider).getEvaluations(measurementId),
);

/// Acciones de escritura sobre el historial.
///
/// Cada operación invalida los providers de lectura para que el historial, la
/// búsqueda y los filtros se reconstruyan con los datos de SQLite.
class MeasurementHistoryNotifier extends Notifier<void> {
  @override
  void build() {}

  MeasurementRepository get _repository =>
      ref.read(measurementRepositoryProvider);

  /// Guarda una medición y, si los hay, sus puntos interiores (muestreo 3D).
  /// Devuelve la medición persistida (con `id`).
  Future<Measurement> save(
    Measurement measurement, {
    List<GeoPoint> interiorPoints = const <GeoPoint>[],
  }) async {
    final saved = await _repository.insertMeasurement(measurement);
    final id = saved.id;
    if (id != null && interiorPoints.isNotEmpty) {
      try {
        await ref.read(interiorPointsStoreProvider).save(id, interiorPoints);
        ref.invalidate(interiorPointsProvider(id));
      } catch (_) {
        // Los puntos interiores son complementarios: un fallo aquí no debe
        // impedir guardar la medición.
      }
    }
    _invalidateHistory();
    return saved;
  }

  Future<void> edit(Measurement measurement) async {
    await _repository.update(measurement);
    _invalidateHistory();
  }

  Future<void> remove(int id) async {
    await _repository.delete(id);
    try {
      await ref.read(interiorPointsStoreProvider).delete(id);
    } catch (_) {}
    ref.invalidate(interiorPointsProvider(id));
    _invalidateHistory();
    ref.invalidate(measurementDetailProvider(id));
  }

  Future<void> removeAll() async {
    await _repository.deleteAll();
    try {
      await ref.read(interiorPointsStoreProvider).deleteAll();
    } catch (_) {}
    _invalidateHistory();
  }

  void _invalidateHistory() {
    ref.invalidate(measurementHistoryProvider);
    ref.invalidate(filteredMeasurementsProvider);
    ref.invalidate(measurementSearchProvider);
  }
}

final measurementHistoryActionsProvider =
    NotifierProvider<MeasurementHistoryNotifier, void>(
  MeasurementHistoryNotifier.new,
);
