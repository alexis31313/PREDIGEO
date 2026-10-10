import 'package:flutter_test/flutter_test.dart';
import 'package:predigeo/domain/entities/geo_point.dart';
import 'package:predigeo/domain/usecases/geo/polygon_validator.dart';

void main() {
  const double mocoaLat = 1.15;
  const double mocoaLon = -76.65;

  final baseTime = DateTime(2026, 3, 15, 10, 30);

  GeoPoint geoPoint(double lat, double lon) {
    return GeoPoint(
      seq: 0,
      latitude: lat,
      longitude: lon,
      altitude: 1800.0,
      accuracy: 5.0,
      timestamp: baseTime,
    );
  }

  group('PolygonValidator.validate', () {
    test('polígono válido (4 puntos, sin autointersección) → isValid true', () {
      final validator = PolygonValidator();

      final result = validator.validate([
        geoPoint(1.15, -76.65),
        geoPoint(1.15, -76.649),
        geoPoint(1.1509, -76.649),
        geoPoint(1.1509, -76.65),
      ]);

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('polígono con menos de 3 puntos → isValid false con mensaje de error', () {
      final validator = PolygonValidator();

      final cases = <List<GeoPoint>>[
        <GeoPoint>[],
        [geoPoint(1.15, -76.65)],
        [geoPoint(1.15, -76.65), geoPoint(1.1509, -76.649)],
      ];

      for (final points in cases) {
        final result = validator.validate(points);
        expect(result.isValid, isFalse);
        expect(result.errors, isNotEmpty);
      }
    });

    test('puntos consecutivos duplicados → isValid false o advertencia', () {
      final validator = PolygonValidator();

      final result = validator.validate([
        geoPoint(1.15, -76.65),
        geoPoint(1.15, -76.649),
        geoPoint(1.15, -76.649),
        geoPoint(1.1509, -76.649),
        geoPoint(1.1509, -76.65),
      ]);

      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('duplicado')), isTrue);
    });

    test('polígono con autointersección (bowtie) → isValid false con mensaje de error', () {
      final validator = PolygonValidator();

      final result = validator.validate([
        geoPoint(1.15, -76.65),
        geoPoint(1.1509, -76.649),
        geoPoint(1.15, -76.649),
        geoPoint(1.1509, -76.65),
      ]);

      expect(result.isValid, isFalse);
      expect(result.errors, isNotEmpty);
    });

    test('polígono complejo válido → isValid true', () {
      final validator = PolygonValidator();

      final result = validator.validate([
        geoPoint(1.15, -76.65),
        geoPoint(1.1509, -76.65),
        geoPoint(1.1509, -76.6491),
        geoPoint(1.15045, -76.6491),
        geoPoint(1.15045, -76.64955),
        geoPoint(1.15, -76.64955),
      ]);

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('triángulo (exactamente 3 puntos) → isValid true', () {
      final validator = PolygonValidator();

      final result = validator.validate([
        geoPoint(1.15, -76.65),
        geoPoint(1.1509, -76.65),
        geoPoint(1.15, -76.649),
      ]);

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });
  });
}
