import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:predigeo/data/export/export_service.dart';
import 'package:predigeo/data/export/export_exception.dart';
import 'package:predigeo/domain/entities/measurement.dart';
import 'package:predigeo/domain/entities/measurement_enums.dart';
import 'package:predigeo/domain/entities/geo_point.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory directorioTemporal;
  late ExportService exportService;

  setUpAll(() {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return Directory.systemTemp.path;
    });
  });

  setUp(() {
    directorioTemporal = Directory.systemTemp.createTempSync('predigeo_export_');
    exportService = ExportService();
  });

  tearDown(() {
    if (directorioTemporal.existsSync()) {
      directorioTemporal.deleteSync(recursive: true);
    }
  });

  Measurement crearMedicion({
    int? id,
    String nombre = 'Medicion Test',
    MeasurementType tipo = MeasurementType.area,
    MeasurementMode modo = MeasurementMode.offline,
    MeasurementCategory? categoria = MeasurementCategory.ruralOpen,
    double? areaM2 = 1500.50,
    double? perimetroM = 180.25,
    double? distanciaM,
    DateTime? fecha,
  }) {
    return Measurement(
      id: id,
      name: nombre,
      type: tipo,
      areaM2: areaM2,
      perimeterM: perimetroM,
      distanceM: distanciaM,
      mode: modo,
      category: categoria,
      createdAt: fecha ?? DateTime(2026, 1, 15, 10, 30, 0),
    );
  }

  List<GeoPoint> crearPuntos() {
    return [
      GeoPoint(seq: 0, latitude: 4.7110, longitude: -74.0721, altitude: 2600.0, accuracy: 3.5, timestamp: DateTime(2026, 1, 15, 10, 30)),
      GeoPoint(seq: 1, latitude: 4.7120, longitude: -74.0731, altitude: 2601.0, accuracy: 4.0, timestamp: DateTime(2026, 1, 15, 10, 30, 5)),
      GeoPoint(seq: 2, latitude: 4.7130, longitude: -74.0741, altitude: 2602.0, accuracy: 3.8, timestamp: DateTime(2026, 1, 15, 10, 30, 10)),
    ];
  }

  group('exportToCSV', () {
    test('crea archivo con encabezado correcto', () async {
      final resultado = await exportService.exportToCSV(crearMedicion(), crearPuntos());
      final contenido = File(resultado).readAsStringSync();
      expect(contenido, contains('id,nombre,tipo,area_m2,perimetro_m,distancia_m,modo,categoria,fecha'));
    });

    test('escapa comillas y comas', () async {
      final resultado = await exportService.exportToCSV(crearMedicion(nombre: 'Medicion, con "comas"'), crearPuntos());
      expect(File(resultado).readAsStringSync(), contains('"Medicion, con ""comas"""'));
    });
  });

  group('exportToGeoJSON', () {
    test('crea GeoJSON válido', () async {
      final resultado = await exportService.exportToGeoJSON(crearMedicion(), crearPuntos());
      final geojson = jsonDecode(File(resultado).readAsStringSync()) as Map<String, dynamic>;
      expect(geojson['type'], 'FeatureCollection');
      final feature = (geojson['features'] as List)[0] as Map<String, dynamic>;
      expect(feature['properties']['name'], 'Medicion Test');
    });

    test('incluye altitud como tercera coordenada', () async {
      final resultado = await exportService.exportToGeoJSON(crearMedicion(), crearPuntos());
      final geojson = jsonDecode(File(resultado).readAsStringSync()) as Map<String, dynamic>;
      final coords = ((geojson['features'] as List)[0] as Map<String, dynamic>)['geometry']['coordinates'] as List;
      final first = (coords[0] as List)[0] as List;
      expect(first.length, 3);
      expect(first[2], 2600.0);
    });
  });

  group('exportToKML', () {
    test('crea KML válido', () async {
      final resultado = await exportService.exportToKML(crearMedicion(), crearPuntos());
      final contenido = File(resultado).readAsStringSync();
      expect(contenido, contains('<?xml version="1.0" encoding="UTF-8"?>'));
      expect(contenido, contains('<Placemark>'));
      expect(contenido, contains('-74.0721,4.711,2600.0'));
    });
  });

  group('exportMultipleToCSV', () {
    test('incluye todas las mediciones', () async {
      final resultado = await exportService.exportMultipleToCSV([
        crearMedicion(id: 1, nombre: 'Terreno A'),
        crearMedicion(id: 2, nombre: 'Terreno B'),
      ]);
      final contenido = File(resultado).readAsStringSync();
      expect(contenido, contains('Terreno A'));
      expect(contenido, contains('Terreno B'));
    });
  });

  group('shareFile', () {
    test('lanza ExportException si el archivo no existe', () {
      expect(() => exportService.shareFile('/ruta/inexistente.txt'), throwsA(isA<ExportException>()));
    });
  });
}
