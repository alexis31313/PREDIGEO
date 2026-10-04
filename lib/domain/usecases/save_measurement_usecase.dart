import '../entities/geo_point.dart';
import '../entities/measurement.dart';
import '../repositories/measurement_repository.dart';

/// Caso de uso que guarda una medición junto con sus puntos GNSS.
///
/// La persistencia es atómica: si falla la escritura de algún punto, no queda
/// ninguna medición a medias en la base de datos local.
class SaveMeasurementUsecase {
  final MeasurementRepository _repository;

  const SaveMeasurementUsecase(this._repository);

  /// Guarda la medición y devuelve la entidad persistida, ya con el `id`
  /// generado por SQLite.
  Future<Measurement> call(
    Measurement measurement, {
    List<GeoPoint> points = const <GeoPoint>[],
  }) {
    return _repository.insertMeasurement(
      points.isEmpty ? measurement : measurement.copyWith(points: points),
    );
  }
}