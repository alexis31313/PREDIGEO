import '../entities/measurement.dart';
import '../repositories/measurement_repository.dart';

/// Caso de uso que obtiene el historial de mediciones almacenadas
/// localmente, de más reciente a más antiguo.
class GetMeasurementsUsecase {
  final MeasurementRepository _repository;

  const GetMeasurementsUsecase(this._repository);

  /// Retorna la lista de mediciones (cabecera, sin puntos) del historial.
  Future<List<Measurement>> call() {
    return _repository.getAll();
  }
}
