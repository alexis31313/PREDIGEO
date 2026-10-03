import '../repositories/measurement_repository.dart';

/// Caso de uso que elimina una medición del almacenamiento por su ID.
class DeleteMeasurementUsecase {
  final MeasurementRepository _repository;

  DeleteMeasurementUsecase(this._repository);

  /// Elimina la medición con el ID especificado.
  Future<void> call(int id) async {
    await _repository.deleteMeasurement(id);
  }
}
