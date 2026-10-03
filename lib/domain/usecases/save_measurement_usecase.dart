import '../entities/measurement.dart';
import '../entities/coordinate.dart';
import '../repositories/measurement_repository.dart';

/// Caso de uso que guarda una medición junto con sus coordenadas asociadas.
class SaveMeasurementUsecase {
  final MeasurementRepository _repository;

  SaveMeasurementUsecase(this._repository);

  /// Guarda una medición y sus coordenadas en el repositorio.
  /// Retorna el ID de la medición guardada.
  Future<int> call(Measurement measurement, List<Coordinate> coordinates) async {
    return await _repository.saveMeasurement(measurement, coordinates);
  }
}
