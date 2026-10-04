// Utilidades compartidas por las pruebas de la capa de persistencia.
//
// Las pruebas se ejecutan sobre `sqflite_common_ffi`, que usa la biblioteca
// SQLite del sistema en lugar del plugin nativo de Android. Así se puede
// verificar la lógica transaccional, las claves foráneas y los índices sin
// necesidad de un dispositivo o emulador.

import 'dart:io';

import 'package:predigeo/data/datasources/database_helper.dart';
import 'package:sqflite/sqflite.dart' show inMemoryDatabasePath;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Inicializa SQLite FFI. Debe invocarse una sola vez por archivo de prueba.
void initSqfliteFfi() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

/// Crea un [DatabaseHelper] aislado sobre una base en memoria.
///
/// La base en memoria se destruye al cerrar la conexión, por lo que cada prueba
/// obtiene un esquema limpio.
Future<DatabaseHelper> createInMemoryDatabase() async {
  final helper = DatabaseHelper.forTesting(
    databasePath: inMemoryDatabasePath,
    factory: databaseFactoryFfi,
  );
  // Fuerza la apertura (y por tanto la creación del esquema).
  await helper.database;
  return helper;
}

/// Crea una ruta de archivo temporal en el directorio de pruebas.
///
/// Necesaria para probar migraciones de esquema: la base debe sobrevivir al
/// cierre de la conexión anterior, algo que no ocurre con `:memory:`.
String createTemporaryDatabasePath() {
  final directory = Directory.systemTemp.createTempSync('predigeo_test_');
  return '${directory.path}${Platform.pathSeparator}predigeo_test.db';
}

/// Construye el esquema heredado (v1) y lo puebla con datos de ejemplo.
///
/// Sirve para verificar la migración `v1 -> v2` conservando la información.
Future<String> createLegacyV1Database(String path) async {
  final db = await databaseFactoryFfi.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE measurements (
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
          CREATE TABLE coordinates (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            altitude REAL NOT NULL,
            accuracy REAL NOT NULL,
            timestamp INTEGER NOT NULL,
            measurement_id INTEGER,
            FOREIGN KEY (measurement_id) REFERENCES measurements (id)
              ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE measurement_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            measurement_id INTEGER NOT NULL,
            start_time INTEGER NOT NULL,
            end_time INTEGER,
            status TEXT NOT NULL,
            FOREIGN KEY (measurement_id) REFERENCES measurements (id)
              ON DELETE CASCADE
          )
        ''');
      },
    ),
  );

  const createdAt = 1714526400000; // 2024-05-01T12:00:00Z
  await db.insert('measurements', {
    'name': 'Lote heredado',
    'area': 1500.0,
    'perimeter': 160.0,
    'distance': 0.0,
    'coordinate_count': 2,
    'measurement_type': 'polygon',
    'created_at': createdAt,
    'notes': 'Medido antes de la actualización',
  });
  await db.insert('coordinates', {
    'latitude': 1.1538,
    'longitude': -76.6510,
    'altitude': 430.0,
    'accuracy': 4.0,
    'timestamp': createdAt,
    'measurement_id': 1,
  });
  await db.insert('coordinates', {
    'latitude': 1.1539,
    'longitude': -76.6511,
    'altitude': 432.0,
    'accuracy': 6.0,
    'timestamp': createdAt + 1000,
    'measurement_id': 1,
  });
  await db.insert('measurement_sessions', {
    'measurement_id': 1,
    'start_time': createdAt,
    'end_time': createdAt + 5000,
    'status': 'completed',
  });

  await db.close();
  return path;
}