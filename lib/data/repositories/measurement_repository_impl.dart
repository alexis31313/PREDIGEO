/// Implementación del repositorio de mediciones para PrediGeo.
/// Gestiona la persistencia de mediciones y coordenadas usando SQLite
/// a través de DatabaseHelper. Proporciona operaciones CRUD completas,
/// exportación a CSV y manejo de transacciones para garantizar
/// la integridad de los datos.
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/coordinate_model.dart';
import '../models/measurement_model.dart';
import '../datasources/local/database_helper.dart';

abstract class MeasurementRepository {
  Future<int> saveMeasurement(MeasurementModel measurement, List<CoordinateModel> coordinates);
  Future<List<MeasurementModel>> getMeasurements();
  Future<MeasurementModel?> getMeasurementById(int id);
  Future<List<CoordinateModel>> getCoordinatesByMeasurementId(int measurementId);
  Future<void> deleteMeasurement(int id);
  Future<void> updateMeasurement(MeasurementModel measurement);
  Future<String> exportAllToCSV();
  Future<int> getMeasurementCount();
}

class MeasurementRepositoryImpl implements MeasurementRepository {
  final DatabaseHelper _databaseHelper;

  MeasurementRepositoryImpl({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper();

  @override
  Future<int> saveMeasurement(
    MeasurementModel measurement,
    List<CoordinateModel> coordinates,
  ) async {
    try {
      final db = await _databaseHelper.database;

      return await db.transaction((txn) async {
        final measurementId = await txn.insert(
          'measurements',
          measurement.toMap(),
        );

        for (final coordinate in coordinates) {
          final coordMap = coordinate.toMap();
          coordMap['measurement_id'] = measurementId;
          await txn.insert('coordinates', coordMap);
        }

        await txn.insert('measurement_sessions', {
          'measurement_id': measurementId,
          'start_time': DateTime.now().millisecondsSinceEpoch,
          'end_time': DateTime.now().millisecondsSinceEpoch,
          'status': 'completed',
        });

        return measurementId;
      });
    } catch (e) {
      throw Exception('Error al guardar la medición: $e');
    }
  }

  @override
  Future<List<MeasurementModel>> getMeasurements() async {
    try {
      return await _databaseHelper.getMeasurements();
    } catch (e) {
      throw Exception('Error al obtener las mediciones: $e');
    }
  }

  @override
  Future<MeasurementModel?> getMeasurementById(int id) async {
    try {
      return await _databaseHelper.getMeasurementById(id);
    } catch (e) {
      throw Exception('Error al obtener la medición por ID: $e');
    }
  }

  @override
  Future<List<CoordinateModel>> getCoordinatesByMeasurementId(int measurementId) async {
    try {
      return await _databaseHelper.getCoordinatesByMeasurementId(measurementId);
    } catch (e) {
      throw Exception('Error al obtener las coordenadas: $e');
    }
  }

  @override
  Future<void> deleteMeasurement(int id) async {
    try {
      final db = await _databaseHelper.database;

      await db.transaction((txn) async {
        await txn.delete(
          'coordinates',
          where: 'measurement_id = ?',
          whereArgs: [id],
        );
        await txn.delete(
          'measurement_sessions',
          where: 'measurement_id = ?',
          whereArgs: [id],
        );
        await txn.delete(
          'measurements',
          where: 'id = ?',
          whereArgs: [id],
        );
      });
    } catch (e) {
      throw Exception('Error al eliminar la medición: $e');
    }
  }

  @override
  Future<void> updateMeasurement(MeasurementModel measurement) async {
    try {
      if (measurement.id == null) {
        throw ArgumentError('La medición debe tener un ID para ser actualizada');
      }
      await _databaseHelper.updateMeasurement(measurement);
    } catch (e) {
      throw Exception('Error al actualizar la medición: $e');
    }
  }

  @override
  Future<String> exportAllToCSV() async {
    try {
      final measurements = await getMeasurements();

      final List<List<dynamic>> rows = [
        [
          'ID',
          'Nombre',
          'Área (m²)',
          'Perímetro (m)',
          'Distancia (m)',
          'N° Coordenadas',
          'Tipo',
          'Fecha Creación',
          'Notas',
        ],
      ];

      for (final measurement in measurements) {
        rows.add([
          measurement.id ?? '',
          measurement.name,
          measurement.area.toStringAsFixed(2),
          measurement.perimeter.toStringAsFixed(2),
          measurement.distance.toStringAsFixed(2),
          measurement.coordinateCount,
          measurement.measurementType,
          measurement.createdAt.toIso8601String(),
          measurement.notes ?? '',
        ]);
      }

      final csv = const ListToCsvConverter().convert(rows);

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = p.join(directory.path, 'predigeo_mediciones_$timestamp.csv');

      final file = File(filePath);
      await file.writeAsString(csv);

      return filePath;
    } catch (e) {
      throw Exception('Error al exportar mediciones a CSV: $e');
    }
  }

  @override
  Future<int> getMeasurementCount() async {
    try {
      return await _databaseHelper.getMeasurementCount();
    } catch (e) {
      throw Exception('Error al obtener el conteo de mediciones: $e');
    }
  }
}
