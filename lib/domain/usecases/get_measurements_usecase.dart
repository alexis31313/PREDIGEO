import '../entities/measurement.dart';
import '../repositories/measurement_repository.dart';

/// Caso de uso que obtiene la lista de todas las mediciones almacenadas.
class GetMeasurementsUsecase {
  final MeasurementRepository _repository;

  GetMeasurementsUsecase(this._repository);

  /// Retorna una lista con todas las mediciones registradas.
  Future<List<Measurement>> call() async {
    return await _repository.getMeasurements();
  }
}
