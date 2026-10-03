import '../repositories/measurement_repository.dart';

/// Caso de uso que exporta todas las mediciones en formato CSV.
class ExportMeasurementsUsecase {
  final MeasurementRepository _repository;

  ExportMeasurementsUsecase(this._repository);

  /// Genera y retorna un string con todas las mediciones en formato CSV.
  Future<String> call() async {
    return await _repository.exportAllToCSV();
  }
}
