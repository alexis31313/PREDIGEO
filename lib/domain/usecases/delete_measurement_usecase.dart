import '../repositories/measurement_repository.dart';

/// Caso de uso que elimina una medición del almacenamiento local.
///
/// Los puntos GNSS y las evaluaciones de campo asociados se eliminan en cascada
/// desde la base de datos, por lo que no quedan datos huérfanos.
class DeleteMeasurementUsecase {
  final MeasurementRepository _repository;

  const DeleteMeasurementUsecase(this._repository);

  /// Elimina la medición con el ID especificado.
  Future<void> call(int id) {
    return _repository.delete(id);
  }
}
