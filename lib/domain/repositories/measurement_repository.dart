import '../entities/measurement.dart';
import '../entities/coordinate.dart';

/// Interfaz del repositorio de mediciones que define las operaciones de persistencia.
abstract class MeasurementRepository {
  Future<int> saveMeasurement(Measurement measurement, List<Coordinate> coordinates);
  Future<List<Measurement>> getMeasurements();
  Future<Measurement?> getMeasurementById(int id);
  Future<List<Coordinate>> getCoordinatesByMeasurementId(int measurementId);
  Future<void> deleteMeasurement(int id);
  Future<void> updateMeasurement(Measurement measurement);
  Future<String> exportAllToCSV();
  Future<int> getMeasurementCount();
}
