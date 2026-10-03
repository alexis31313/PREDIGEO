/// Asistente de base de datos SQLite para PrediGeo.
/// Implementa el patrón Singleton para gestionar la base de datos local
/// que almacena coordenadas, mediciones y sesiones de medición.
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/coordinate_model.dart';
import '../../models/measurement_model.dart';
import '../../../core/constants/app_constants.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, AppConstants.databaseName);

      return await openDatabase(
        path,
        version: AppConstants.databaseVersion,
        onCreate: _onCreate,
      );
    } catch (e) {
      throw Exception('Error al inicializar la base de datos: $e');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE ${AppConstants.tableCoordinates} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          altitude REAL NOT NULL,
          accuracy REAL NOT NULL,
          timestamp INTEGER NOT NULL,
          measurement_id INTEGER,
          FOREIGN KEY (measurement_id) REFERENCES ${AppConstants.tableMeasurements} (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE ${AppConstants.tableMeasurements} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          area REAL NOT NULL,
          perimeter REAL NOT NULL,
          distance REAL NOT NULL,
          coordinate_count INTEGER NOT NULL,
          measurement_type TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          notes TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE ${AppConstants.tableSessions} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          measurement_id INTEGER NOT NULL,
          start_time INTEGER NOT NULL,
          end_time INTEGER,
          status TEXT NOT NULL,
          FOREIGN KEY (measurement_id) REFERENCES ${AppConstants.tableMeasurements} (id) ON DELETE CASCADE
        )
      ''');
    } catch (e) {
      throw Exception('Error al crear las tablas: $e');
    }
  }

  Future<int> insertCoordinate(CoordinateModel coordinate, {int? measurementId}) async {
    try {
      final db = await database;
      final map = coordinate.toMap();
      if (measurementId != null) {
        map['measurement_id'] = measurementId;
      } else {
        map.remove('measurement_id');
      }
      return await db.insert(AppConstants.tableCoordinates, map);
    } catch (e) {
      throw Exception('Error al insertar coordenada: $e');
    }
  }

  Future<int> insertMeasurement(MeasurementModel measurement) async {
    try {
      final db = await database;
      return await db.insert(AppConstants.tableMeasurements, measurement.toMap());
    } catch (e) {
      throw Exception('Error al insertar medición: $e');
    }
  }

  Future<int> insertSession({
    required int measurementId,
    required DateTime startTime,
    DateTime? endTime,
    required String status,
  }) async {
    try {
      final db = await database;
      return await db.insert(AppConstants.tableSessions, {
        'measurement_id': measurementId,
        'start_time': startTime.millisecondsSinceEpoch,
        'end_time': endTime?.millisecondsSinceEpoch,
        'status': status,
      });
    } catch (e) {
      throw Exception('Error al insertar sesión: $e');
    }
  }

  Future<List<MeasurementModel>> getMeasurements() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        AppConstants.tableMeasurements,
        orderBy: 'created_at DESC',
      );
      return maps.map((map) => MeasurementModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener mediciones: $e');
    }
  }

  Future<MeasurementModel?> getMeasurementById(int id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        AppConstants.tableMeasurements,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isEmpty) return null;
      return MeasurementModel.fromMap(maps.first);
    } catch (e) {
      throw Exception('Error al obtener medición por ID: $e');
    }
  }

  Future<List<CoordinateModel>> getCoordinatesByMeasurementId(int measurementId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        AppConstants.tableCoordinates,
        where: 'measurement_id = ?',
        whereArgs: [measurementId],
        orderBy: 'timestamp ASC',
      );
      return maps.map((map) => CoordinateModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener coordenadas por medición: $e');
    }
  }

  Future<int> deleteMeasurement(int id) async {
    try {
      final db = await database;
      return await db.delete(
        AppConstants.tableMeasurements,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Error al eliminar medición: $e');
    }
  }

  Future<int> deleteCoordinatesByMeasurementId(int measurementId) async {
    try {
      final db = await database;
      return await db.delete(
        AppConstants.tableCoordinates,
        where: 'measurement_id = ?',
        whereArgs: [measurementId],
      );
    } catch (e) {
      throw Exception('Error al eliminar coordenadas: $e');
    }
  }

  Future<int> updateMeasurement(MeasurementModel measurement) async {
    try {
      final db = await database;
      return await db.update(
        AppConstants.tableMeasurements,
        measurement.toMap(),
        where: 'id = ?',
        whereArgs: [measurement.id],
      );
    } catch (e) {
      throw Exception('Error al actualizar medición: $e');
    }
  }

  Future<int> getMeasurementCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${AppConstants.tableMeasurements}',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw Exception('Error al obtener conteo de mediciones: $e');
    }
  }

  Future<void> closeDatabase() async {
    try {
      final db = _database;
      if (db != null && db.isOpen) {
        await db.close();
        _database = null;
      }
    } catch (e) {
      throw Exception('Error al cerrar la base de datos: $e');
    }
  }
}
