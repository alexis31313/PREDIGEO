import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:predigeo/data/export/export_service.dart';
import 'package:predigeo/domain/entities/geo_point.dart';
import 'package:predigeo/domain/entities/measurement.dart';
import 'package:predigeo/domain/entities/measurement_enums.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory directorioTemporal;

  setUpAll(() {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return Directory.systemTemp.path;
    });
  });

  setUp(() {
    directorioTemporal = Directory.systemTemp.createTempSync('predigeo_fmt_');
  });

  tearDown(() {
    if (directorioTemporal.existsSync()) {
      directorioTemporal.deleteSync(recursive: true);
    }
  });
  final samplePoints = [
    GeoPoint(
      seq: 0,
      latitude: 4.7110,
      longitude: -74.0721,
      altitude: 2600.0,
      accuracy: 3.5,
      timestamp: DateTime(2024, 1, 15, 10, 30),
    ),
    GeoPoint(
      seq: 1,
      latitude: 4.7120,
      longitude: -74.0731,
      altitude: 2605.0,
      accuracy: 3.2,
      timestamp: DateTime(2024, 1, 15, 10, 31),
    ),
  ];

  final sampleMeasurement = Measurement(
    id: 1,
    name: 'Test, "Special"',
    type: MeasurementType.area,
    areaM2: 1250.5,
    perimeterM: 145.2,
    mode: MeasurementMode.online,
    category: MeasurementCategory.ruralOpen,
    createdAt: DateTime(2024, 1, 15, 10, 0),
    points: samplePoints,
  );

  group('ExportService', () {
    test('Test CSV format has correct headers and escaping', () async {
      final service = ExportService();
      final path = await service.exportToCSV(sampleMeasurement, samplePoints);
      final csv = File(path).readAsStringSync();

      final lines = csv.split('\n');
      expect(lines[0], 'id,nombre,tipo,area_m2,perimetro_m,distancia_m,modo,categoria,fecha');
      expect(lines[1], contains('"Test, ""Special"""'));
      expect(lines[1], contains('1250.5'));
      expect(lines[1], contains('area'));
    });

    test('Test GeoJSON is valid JSON with correct structure', () async {
      final service = ExportService();
      final path = await service.exportToGeoJSON(sampleMeasurement, samplePoints);
      final geoJson = File(path).readAsStringSync();

      final decoded = jsonDecode(geoJson) as Map<String, dynamic>;
      expect(decoded['type'], 'FeatureCollection');
      expect(decoded['features'], isA<List>());
      expect((decoded['features'] as List).length, 1);

      final feature = decoded['features'][0] as Map<String, dynamic>;
      expect(feature['type'], 'Feature');
      expect(feature['geometry']['type'], 'Polygon');
      expect(feature['properties']['name'], 'Test, "Special"');
    });

    test('Test KML has correct XML structure', () async {
      final service = ExportService();
      final path = await service.exportToKML(sampleMeasurement, samplePoints);
      final kml = File(path).readAsStringSync();

      expect(kml, contains('<?xml version="1.0" encoding="UTF-8"?>'));
      expect(kml, contains('<kml xmlns="http://www.opengis.net/kml/2.2">'));
      expect(kml, contains('<Placemark>'));
      expect(kml, contains('<name>'));
      expect(kml, contains('<coordinates>'));
      expect(kml.contains('2600'), isTrue);
    });

    test('Test altitude is included in coordinates', () async {
      final service = ExportService();
      final geoPath = await service.exportToGeoJSON(sampleMeasurement, samplePoints);
      final geoJson = File(geoPath).readAsStringSync();
      final decoded = jsonDecode(geoJson);
      final coords = (decoded['features'][0] as Map<String, dynamic>)['geometry']['coordinates'][0] as List;

      expect(coords[0][2], 2600.0);
      expect(coords[1][2], 2605.0);

      final kmlPath = await service.exportToKML(sampleMeasurement, samplePoints);
      final kml = File(kmlPath).readAsStringSync();
      expect(kml, contains('2600.0'));
      expect(kml, contains('2605.0'));
    });
  });
}
