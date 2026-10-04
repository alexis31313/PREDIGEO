// Pruebas del esquema local: creación de tablas, restricciones, claves
// foráneas, índices y migración del esquema heredado (v1) al actual (v2).

import 'package:flutter_test/flutter_test.dart';
import 'package:predigeo/core/constants/app_constants.dart';
import 'package:predigeo/data/datasources/database_helper.dart';
import 'package:predigeo/data/models/measurement_model.dart';
import 'package:predigeo/data/repositories/sqlite_measurement_repository.dart';
import 'package:predigeo/domain/entities/measurement_enums.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../support/fixtures.dart';
import '../../support/test_database.dart';

void main() {
  setUpAll(initSqfliteFfi);

  group('esquema', () {
    late DatabaseHelper helper;
    late Database db;

    setUp(() async {
      helper = await createInMemoryDatabase();
      db = await helper.database;
    });

    tearDown(() async {
      await helper.close();
    });

    Future<List<String>> columnsOf(String table) async {
      final info = await db.rawQuery('PRAGMA table_info($table)');
      return info.map((row) => row['name'] as String).toList();
    }

    Future<List<String>> indexesOf(String table) async {
      final info = await db.rawQuery('PRAGMA index_list($table)');
      return info.map((row) => row['name'] as String).toList();
    }

    test('crea las tres tablas del modelo actual', () async {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );
      final names =
          tables.map((row) => row['name'] as String).toSet();

      expect(names, contains(AppConstants.tableMeasurements));
      expect(names, contains(AppConstants.tableMeasurementPoints));
      expect(names, contains(AppConstants.tableFieldEvaluations));
    });

    test('measurements contiene todas las columnas del modelo', () async {
      expect(
        await columnsOf(AppConstants.tableMeasurements),
        containsAll(<String>[
          'id',
          'name',
          'type',
          'area_m2',
          'perimeter_m',
          'distance_m',
          'mode',
          'category',
          'notes',
          'avg_accuracy_m',
          'created_at',
        ]),
      );
    });

    test('measurement_points contiene todas las columnas del modelo', () async {
      expect(
        await columnsOf(AppConstants.tableMeasurementPoints),
        containsAll(<String>[
          'id',
          'measurement_id',
          'seq',
          'latitude',
          'longitude',
          'altitude',
          'accuracy',
          'timestamp',
        ]),
      );
    });

    test('field_evaluations contiene todas las columnas del modelo', () async {
      expect(
        await columnsOf(AppConstants.tableFieldEvaluations),
        containsAll(<String>[
          'id',
          'measurement_id',
          'reference_value',
          'reference_source',
          'reference_type',
          'env_conditions',
        ]),
      );
    });

    test('tiene claves foráneas activas en la conexión', () async {
      final rows = await db.rawQuery('PRAGMA foreign_keys');
      expect(rows.first.values.first, 1);
    });

    test('crea el índice del historial por created_at', () async {
      final indexes = await indexesOf(AppConstants.tableMeasurements);

      expect(indexes, contains(AppConstants.indexMeasurementsCreatedAt));

      final info = await db.rawQuery(
        'PRAGMA index_info(${AppConstants.indexMeasurementsCreatedAt})',
      );
      expect(info.map((row) => row['name']), ['created_at']);
    });

    test('crea el índice de puntos por medición y secuencia', () async {
      expect(
        await indexesOf(AppConstants.tableMeasurementPoints),
        contains(AppConstants.indexMeasurementPointsSeq),
      );
      expect(
        await indexesOf(AppConstants.tableFieldEvaluations),
        contains(AppConstants.indexFieldEvaluationsMeasurementId),
      );
    });

    test('declara la clave foránea de los hijos con ON DELETE CASCADE',
        () async {
      for (final table in <String>[
        AppConstants.tableMeasurementPoints,
        AppConstants.tableFieldEvaluations,
      ]) {
        final fks = await db.rawQuery('PRAGMA foreign_key_list($table)');
        expect(fks, hasLength(1));
        expect(fks.first['table'], AppConstants.tableMeasurements);
        expect(fks.first['on_delete'], 'CASCADE');
      }
    });

    test('rechaza tipos, modos y categorías fuera del dominio', () async {
      Future<void> insertInvalid(String column, String value) async {
        final row = <String, Object?>{
          'name': 'Inválida',
          'type': 'area',
          'mode': 'offline',
          'created_at': DateTime.now().toUtc().toIso8601String(),
          column: value,
        };
        await expectLater(
          helper.insert(AppConstants.tableMeasurements, row),
          throwsA(isA<DatabaseException>()),
        );
      }

      await insertInvalid('type', 'triangle');
      await insertInvalid('mode', 'satellite');
      await insertInvalid('category', 'rural_closed');
    });

    test('rechaza coordenadas fuera del rango geodésico válido', () async {
      final id = await helper.insert(AppConstants.tableMeasurements, {
        'name': 'Con punto inválido',
        'type': 'path',
        'mode': 'offline',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      await expectLater(
        helper.insert(AppConstants.tableMeasurementPoints, {
          'measurement_id': id,
          'seq': 0,
          'latitude': 91.0,
          'longitude': -76.6,
          'altitude': 430.0,
          'accuracy': 4.0,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        }),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('no permite dos puntos con el mismo seq en una medición', () async {
      final repository = SqliteMeasurementRepository(helper);
      final saved = await repository.insertMeasurement(
        buildMeasurement(points: []),
      );

      Future<void> insertPoint(int seq) async {
        await helper.insert(AppConstants.tableMeasurementPoints, {
          'measurement_id': saved.id,
          'seq': seq,
          'latitude': 1.15,
          'longitude': -76.65,
          'altitude': 430.0,
          'accuracy': 4.0,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        });
      }

      await insertPoint(0);
      await expectLater(insertPoint(0), throwsA(isA<DatabaseException>()));
    });
  });

  group('migración v1 -> v2', () {
    test('conserva las mediciones y coordenadas del esquema heredado',
        () async {
      final path = createTemporaryDatabasePath();
      await createLegacyV1Database(path);

      final helper = DatabaseHelper.forTesting(
        databasePath: path,
        factory: databaseFactoryFfi,
      );
      addTearDown(helper.close);

      final repository = SqliteMeasurementRepository(helper);
      final migrated = await repository.getAll();

      expect(migrated, hasLength(1));

      final measurement = migrated.single;
      expect(measurement.name, 'Lote heredado');
      expect(measurement.type, MeasurementType.area);
      expect(measurement.mode, MeasurementMode.offline);
      expect(measurement.category, isNull);
      expect(measurement.areaM2, 1500.0);
      expect(measurement.perimeterM, 160.0);
      expect(measurement.notes, 'Medido antes de la actualización');
      expect(measurement.createdAt.toUtc().year, 2024);
      expect(measurement.avgAccuracyM, 5.0); // promedio de 4.0 y 6.0

      final full = await repository.getById(measurement.id!);
      expect(full!.points, hasLength(2));
      expect(full.points[0].seq, 0);
      expect(full.points[1].seq, 1);
      expect(full.points.first.latitude, closeTo(1.1538, 1e-9));
      expect(full.points.first.timestamp.toUtc().year, 2024);
    });

    test('elimina las tablas del esquema heredado', () async {
      final path = createTemporaryDatabasePath();
      await createLegacyV1Database(path);

      final helper = DatabaseHelper.forTesting(
        databasePath: path,
        factory: databaseFactoryFfi,
      );
      addTearDown(helper.close);

      final db = await helper.database;
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );
      final names = tables.map((row) => row['name'] as String).toSet();

      expect(names, isNot(contains(AppConstants.legacyTableCoordinates)));
      expect(names, isNot(contains(AppConstants.legacyTableSessions)));
      expect(
        names,
        containsAll(<String>[
          AppConstants.tableMeasurements,
          AppConstants.tableMeasurementPoints,
          AppConstants.tableFieldEvaluations,
        ]),
      );
    });

    test('permite seguir guardando mediciones tras la migración', () async {
      final path = createTemporaryDatabasePath();
      await createLegacyV1Database(path);

      final helper = DatabaseHelper.forTesting(
        databasePath: path,
        factory: databaseFactoryFfi,
      );
      addTearDown(helper.close);

      final repository = SqliteMeasurementRepository(helper);
      final saved = await repository.insertMeasurement(
        buildMeasurement(name: 'Post migración'),
      );

      expect(saved.id, isNotNull);
      expect(await repository.count(), 2);
    });
  });

  group('cierre de la conexión', () {
    test('close es idempotente', () async {
      final helper = await createInMemoryDatabase();
      await helper.close();
      await expectLater(helper.close(), completes);
    });
  });

  group('modelos de datos', () {
    test('MeasurementModel conserva todos los campos en el ida y vuelta', () {
      final entity = buildMeasurement(
        id: 7,
        name: 'Lote con acentos: Mocoa, Putumayo',
        type: MeasurementType.path,
        mode: MeasurementMode.online,
        category: MeasurementCategory.urban,
        areaM2: null,
        perimeterM: null,
        distanceM: 1234.5,
        avgAccuracyM: 3.5,
        notes: 'Trayecto con línea 12',
        createdAt: DateTime(2026, 7, 1, 8, 15, 30, 250),
      );

      final model = MeasurementModel.fromEntity(entity);
      final restored = model.toEntity();

      expect(restored.id, 7);
      expect(restored.name, entity.name);
      expect(restored.type, MeasurementType.path);
      expect(restored.mode, MeasurementMode.online);
      expect(restored.category, MeasurementCategory.urban);
      expect(restored.areaM2, isNull);
      expect(restored.distanceM, 1234.5);
      expect(restored.avgAccuracyM, 3.5);
      expect(restored.createdAt, entity.createdAt);
    });

    test('serializa las fechas en UTC ISO8601', () {
      final entity = buildMeasurement(
        createdAt: DateTime(2026, 7, 1, 8, 15, 30),
      );

      final row = MeasurementModel.fromEntity(entity).toMap();

      expect(row['created_at'], endsWith('Z'));
      expect(DateTime.parse(row['created_at']! as String).isUtc, isTrue);
    });

    test('lanza ArgumentError con un type desconocido', () {
      expect(
        () => MeasurementModel.fromMap(<String, Object?>{
          'id': 1,
          'name': 'Corrupta',
          'type': 'triangle',
          'mode': 'offline',
          'created_at': '2026-07-01T08:15:30.000Z',
        }),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}