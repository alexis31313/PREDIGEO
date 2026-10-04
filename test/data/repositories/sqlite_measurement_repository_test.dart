// Pruebas de la implementación SQLite del repositorio de mediciones.
// Se ejecutan sobre sqflite_common_ffi: verifican persistencia, atomicidad,
// borrado en cascada, búsquedas y filtros.

import 'package:flutter_test/flutter_test.dart';
import 'package:predigeo/core/constants/app_constants.dart';
import 'package:predigeo/core/errors/exceptions.dart';
import 'package:predigeo/data/datasources/database_helper.dart';
import 'package:predigeo/data/repositories/sqlite_measurement_repository.dart';
import 'package:predigeo/domain/entities/geo_point.dart';
import 'package:predigeo/domain/entities/measurement_enums.dart';
import 'package:predigeo/domain/repositories/measurement_repository.dart';

import '../../support/fixtures.dart';
import '../../support/test_database.dart';

void main() {
  late DatabaseHelper helper;
  late MeasurementRepository repository;

  setUpAll(initSqfliteFfi);

  setUp(() async {
    helper = await createInMemoryDatabase();
    repository = SqliteMeasurementRepository(helper);
  });

  tearDown(() async {
    await helper.close();
  });

  /// Consulta el conteo directo en SQLite para verificar el efecto real de las
  /// claves foráneas (no solo lo que devuelve el repositorio).
  Future<int> countRows(String table) async {
    final db = await helper.database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS total FROM $table');
    return (rows.first['total'] as int?) ?? 0;
  }

  group('insertMeasurement', () {
    test('persiste la cabecera, los puntos y las evaluaciones', () async {
      final saved = await repository.insertMeasurement(
        buildMeasurement(
          name: 'Finca El Mirador',
          points: buildPolygonPoints(),
          evaluations: [buildEvaluation(referenceValue: 1234.5)],
        ),
      );

      // Cabecera con id generado.
      expect(saved.id, isNotNull);
      expect(saved.name, 'Finca El Mirador');
      expect(saved.type, MeasurementType.area);
      expect(saved.mode, MeasurementMode.offline);
      expect(saved.category, MeasurementCategory.ruralOpen);
      expect(saved.areaM2, 1200.0);
      expect(saved.perimeterM, 140.0);
      expect(saved.points, hasLength(4));
      expect(saved.evaluations, hasLength(1));
      expect(saved.evaluations.first.id, isNotNull);
      expect(saved.evaluations.first.measurementId, saved.id);

      // La precisión media se calcula a partir de los puntos.
      expect(saved.avgAccuracyM, 4.0);

      // Filas reales en cada tabla.
      expect(await countRows(AppConstants.tableMeasurements), 1);
      expect(await countRows(AppConstants.tableMeasurementPoints), 4);
      expect(await countRows(AppConstants.tableFieldEvaluations), 1);
    });

    test('renumera seq según el orden de la lista de puntos', () async {
      final points = buildPolygonPoints().reversed.toList();
      final saved = await repository.insertMeasurement(
        buildMeasurement(points: points),
      );

      expect(
        saved.points.map((point) => point.seq),
        [0, 1, 2, 3],
      );
      expect(
        saved.points.map((point) => point.measurementId).toSet(),
        {saved.id},
      );
    });

    test('conserva la precisión media indicada por el usuario', () async {
      final saved = await repository.insertMeasurement(
        buildMeasurement(
          avgAccuracyM: 7.25,
          points: buildPolygonPoints(),
        ),
      );

      expect(saved.avgAccuracyM, 7.25);
    });

    test('es atómica: si un punto es inválido no queda medición guardada',
        () async {
      final invalidPoints = <GeoPoint>[
        buildPoint(seq: 0),
        buildPoint(seq: 1, latitude: 120.0), // fuera del rango [-90, 90]
        buildPoint(seq: 2),
      ];

      await expectLater(
        repository.insertMeasurement(buildMeasurement(points: invalidPoints)),
        throwsA(isA<ValidationException>()),
      );

      expect(await repository.count(), 0);
      expect(await countRows(AppConstants.tableMeasurementPoints), 0);
    });

    test('rechaza mediciones sin nombre', () async {
      await expectLater(
        repository.insertMeasurement(buildMeasurement(name: '   ')),
        throwsA(isA<ValidationException>()),
      );
      expect(await repository.count(), 0);
    });

    test('revierte la transacción si un punto viola la base de datos',
        () async {
      // Se omite la validación previa insertando directamente un punto con
      // precisión negativa: el CHECK de SQLite debe abortar la transacción.
      await expectLater(
        helper.transaction((txn) async {
          final id = await txn.insert(AppConstants.tableMeasurements, {
            AppConstants.columnName: 'Medición directa',
            AppConstants.columnType: 'area',
            AppConstants.columnMode: 'offline',
            AppConstants.columnCreatedAt: DateTime.now().toIso8601String(),
          });
          await txn.insert(AppConstants.tableMeasurementPoints, {
            AppConstants.columnMeasurementId: id,
            AppConstants.columnSeq: 0,
            AppConstants.columnLatitude: 1.0,
            AppConstants.columnLongitude: -76.6,
            AppConstants.columnAltitude: 400.0,
            AppConstants.columnAccuracy: -1.0,
            AppConstants.columnTimestamp: DateTime.now().toIso8601String(),
          });
        }),
        throwsA(anything),
      );

      expect(await countRows(AppConstants.tableMeasurements), 0);
    });
  });

  group('getById', () {
    test('devuelve la medición con puntos ordenados y evaluaciones', () async {
      final inserted = await repository.insertMeasurement(
        buildMeasurement(
          name: 'Lote ordenado',
          points: buildPolygonPoints(),
          evaluations: [
            buildEvaluation(referenceValue: 1000.0),
            buildEvaluation(
              referenceValue: 800.0,
              referenceType: ReferenceType.distance,
            ),
          ],
        ),
      );

      final loaded = await repository.getById(inserted.id!);

      expect(loaded, isNotNull);
      expect(loaded!.id, inserted.id);
      expect(loaded.points.map((p) => p.seq), [0, 1, 2, 3]);
      expect(loaded.points.first.latitude, 1.15380);
      expect(loaded.points.first.id, isNotNull);
      expect(loaded.evaluations, hasLength(2));
      expect(loaded.evaluations.first.referenceType, ReferenceType.area);
      expect(loaded.evaluations.last.referenceType, ReferenceType.distance);
    });

    test('devuelve null cuando la medición no existe', () async {
      expect(await repository.getById(9999), isNull);
    });

    test('conserva las marcas de tiempo ISO8601 con precisión de milisegundos',
        () async {
      final createdAt = DateTime(2026, 3, 15, 14, 30, 45, 123);
      final inserted = await repository.insertMeasurement(
        buildMeasurement(createdAt: createdAt, points: [buildPoint()]),
      );

      final loaded = await repository.getById(inserted.id!);

      expect(loaded!.createdAt, createdAt);
      expect(loaded.points.first.timestamp, DateTime(2026, 3, 15, 14, 30));
    });
  });

  group('getAll', () {
    test('ordena de más reciente a más antigua y sin puntos', () async {
      await repository.insertMeasurement(
        buildMeasurement(name: 'Antigua', createdAt: DateTime(2026, 1, 10)),
      );
      await repository.insertMeasurement(
        buildMeasurement(
          name: 'Reciente',
          createdAt: DateTime(2026, 5, 20),
          points: buildPolygonPoints(),
        ),
      );
      await repository.insertMeasurement(
        buildMeasurement(name: 'Intermedia', createdAt: DateTime(2026, 3, 2)),
      );

      final all = await repository.getAll();

      expect(
        all.map((measurement) => measurement.name).toList(),
        ['Reciente', 'Intermedia', 'Antigua'],
      );
      // La cabecera del historial no carga los puntos.
      expect(all.first.points, isEmpty);
      expect(all.first.evaluations, isEmpty);
    });
  });

  group('update', () {
    test('actualiza la cabecera y reemplaza los puntos', () async {
      final inserted = await repository.insertMeasurement(
        buildMeasurement(name: 'Antes', points: buildPolygonPoints()),
      );

      final updated = await repository.update(
        inserted.copyWith(
          name: 'Después',
          notes: 'Notas editadas',
          areaM2: 999.0,
          points: <GeoPoint>[buildPoint(seq: 0), buildPoint(seq: 1)],
        ),
      );

      expect(updated.id, inserted.id);
      expect(updated.name, 'Después');
      expect(updated.notes, 'Notas editadas');
      expect(updated.areaM2, 999.0);
      expect(updated.points, hasLength(2));

      final rows = await helper.query(
        AppConstants.tableMeasurementPoints,
        where: '${AppConstants.columnMeasurementId} = ?',
        whereArgs: [inserted.id],
      );
      expect(rows, hasLength(2));
      // created_at es inmutable.
      expect(updated.createdAt, inserted.createdAt);
    });

    test('no permite actualizar una medición sin id', () async {
      await expectLater(
        repository.update(buildMeasurement()),
        throwsA(isA<ValidationException>()),
      );
    });

    test('falla si la medición no existe', () async {
      await expectLater(
        repository.update(buildMeasurement(id: 4242)),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('delete', () {
    test('elimina en cascada puntos y evaluaciones', () async {
      final inserted = await repository.insertMeasurement(
        buildMeasurement(
          points: buildPolygonPoints(),
          evaluations: [buildEvaluation()],
        ),
      );

      await repository.delete(inserted.id!);

      expect(await repository.getById(inserted.id!), isNull);
      expect(await countRows(AppConstants.tableMeasurementPoints), 0);
      expect(await countRows(AppConstants.tableFieldEvaluations), 0);
    });

    test('no afecta otras mediciones', () async {
      final first = await repository.insertMeasurement(
        buildMeasurement(name: 'A', points: buildPolygonPoints()),
      );
      await repository.insertMeasurement(
        buildMeasurement(name: 'B', points: buildPolygonPoints()),
      );

      await repository.delete(first.id!);

      final all = await repository.getAll();
      expect(all, hasLength(1));
      expect(all.single.name, 'B');
    });

    test('es idempotente cuando el id no existe', () async {
      await expectLater(repository.delete(777), completes);
      expect(await repository.count(), 0);
    });
  });

  group('deleteAll', () {
    test('vacía el historial completo', () async {
      for (var i = 0; i < 3; i++) {
        await repository.insertMeasurement(
          buildMeasurement(
            name: 'Medición $i',
            points: buildPolygonPoints(),
            evaluations: [buildEvaluation()],
          ),
        );
      }

      final deleted = await repository.deleteAll();

      expect(deleted, 3);
      expect(await repository.count(), 0);
      expect(await countRows(AppConstants.tableMeasurementPoints), 0);
      expect(await countRows(AppConstants.tableFieldEvaluations), 0);
    });
  });

  group('search', () {
    test('busca por coincidencia parcial sin distinguir mayúsculas', () async {
      await repository.insertMeasurement(buildMeasurement(name: 'Finca El Mirador'));
      await repository.insertMeasurement(buildMeasurement(name: 'Lote Norte'));
      await repository.insertMeasurement(buildMeasurement(name: 'Potrero Sur'));

      final results = await repository.search('finca');

      expect(results, hasLength(1));
      expect(results.single.name, 'Finca El Mirador');
    });

    test('devuelve todas las mediciones con un término vacío', () async {
      await repository.insertMeasurement(buildMeasurement(name: 'A'));
      await repository.insertMeasurement(buildMeasurement(name: 'B'));

      expect(await repository.search(''), hasLength(2));
      expect(await repository.search('   '), hasLength(2));
      expect(await repository.search(null), hasLength(2));
    });

    test('trata los comodines de LIKE como texto literal', () async {
      await repository.insertMeasurement(buildMeasurement(name: 'Lote 50%'));
      await repository.insertMeasurement(buildMeasurement(name: 'Lote 100'));

      final percent = await repository.search('50%');
      expect(percent, hasLength(1));
      expect(percent.single.name, 'Lote 50%');

      final wildcard = await repository.search('%');
      expect(wildcard, hasLength(1));
      expect(wildcard.single.name, 'Lote 50%');
    });

    test('devuelve vacío cuando no hay coincidencias', () async {
      await repository.insertMeasurement(buildMeasurement(name: 'Lote Norte'));
      expect(await repository.search('quebrada'), isEmpty);
    });
  });

  group('filter', () {
    Future<void> seed() async {
      await repository.insertMeasurement(
        buildMeasurement(
          name: 'Pasto 1',
          type: MeasurementType.area,
          mode: MeasurementMode.offline,
          category: MeasurementCategory.ruralOpen,
          createdAt: DateTime(2026, 1, 5),
        ),
      );
      await repository.insertMeasurement(
        buildMeasurement(
          name: 'Bosque 1',
          type: MeasurementType.area,
          mode: MeasurementMode.online,
          category: MeasurementCategory.ruralVegetation,
          createdAt: DateTime(2026, 2, 5),
        ),
      );
      await repository.insertMeasurement(
        buildMeasurement(
          name: 'Trayecto urbano',
          type: MeasurementType.path,
          mode: MeasurementMode.offline,
          category: MeasurementCategory.urban,
          createdAt: DateTime(2026, 3, 5),
        ),
      );
      await repository.insertMeasurement(
        buildMeasurement(
          name: 'Sin categoría',
          type: MeasurementType.path,
          mode: MeasurementMode.online,
          category: null,
          createdAt: DateTime(2026, 4, 5),
        ),
      );
    }

    test('sin filtros devuelve todo el historial', () async {
      await seed();
      expect(await repository.filter(), hasLength(4));
    });

    test('filtra por tipo', () async {
      await seed();
      final areas = await repository.filter(type: MeasurementType.area);
      expect(areas.map((m) => m.name), ['Bosque 1', 'Pasto 1']);

      final paths = await repository.filter(type: MeasurementType.path);
      expect(paths.map((m) => m.name), ['Sin categoría', 'Trayecto urbano']);
    });

    test('filtra por modalidad de captura', () async {
      await seed();
      final offline =
          await repository.filter(mode: MeasurementMode.offline);
      expect(offline.map((m) => m.name), ['Trayecto urbano', 'Pasto 1']);

      final online = await repository.filter(mode: MeasurementMode.online);
      expect(online.map((m) => m.name), ['Sin categoría', 'Bosque 1']);
    });

    test('filtra por categoría de terreno', () async {
      await seed();
      final ruralOpen =
          await repository.filter(category: MeasurementCategory.ruralOpen);
      expect(ruralOpen.single.name, 'Pasto 1');

      final urban = await repository.filter(category: MeasurementCategory.urban);
      expect(urban.single.name, 'Trayecto urbano');
    });

    test('combina varios criterios', () async {
      await seed();
      final results = await repository.filter(
        type: MeasurementType.path,
        mode: MeasurementMode.offline,
        category: MeasurementCategory.urban,
      );

      expect(results.single.name, 'Trayecto urbano');
    });

    test('filtra las mediciones sin categoría', () async {
      await seed();
      final uncategorized = await repository.filter(onlyUncategorized: true);
      expect(uncategorized.single.name, 'Sin categoría');
    });

    test('un criterio sin coincidencias devuelve lista vacía', () async {
      await seed();
      final results = await repository.filter(
        type: MeasurementType.area,
        category: MeasurementCategory.urban,
      );
      expect(results, isEmpty);
    });
  });

  group('field evaluations', () {
    test('inserta y recupera evaluaciones de una medición', () async {
      final inserted = await repository.insertMeasurement(
        buildMeasurement(name: 'Lote evaluado'),
      );

      final evaluation = await repository.insertEvaluation(
        buildEvaluation(measurementId: inserted.id!, referenceValue: 1180.75),
      );

      expect(evaluation.id, isNotNull);
      expect(evaluation.measurementId, inserted.id);

      final evaluations = await repository.getEvaluations(inserted.id!);
      expect(evaluations, hasLength(1));
      expect(evaluations.single.referenceValue, 1180.75);
      expect(evaluations.single.referenceSource, 'Agrimensura');
    });

    test('falla si la medición asociada no existe', () async {
      await expectLater(
        repository.insertEvaluation(buildEvaluation(measurementId: 999)),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('count', () {
    test('refleja la cantidad de mediciones almacenadas', () async {
      expect(await repository.count(), 0);
      await repository.insertMeasurement(buildMeasurement(name: 'A'));
      await repository.insertMeasurement(buildMeasurement(name: 'B'));
      expect(await repository.count(), 2);
    });
  });
}