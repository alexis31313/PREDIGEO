// Pruebas de la entidad GpsReading.
// Verifica el mapeo desde Position de geolocator, copyWith, igualdad y toString.

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:predigeo/domain/entities/gps_reading.dart';

class MockPosition extends Mock implements Position {}

void main() {
  late MockPosition mockPosition;

  setUp(() {
    mockPosition = MockPosition();
  });

  group('GpsReading.fromPosition', () {
    test('mapea todos los campos correctamente', () {
      const timestamp = '2026-03-15T10:30:00.000';
      when(() => mockPosition.latitude).thenReturn(4.7110);
      when(() => mockPosition.longitude).thenReturn(-74.0721);
      when(() => mockPosition.altitude).thenReturn(2600.0);
      when(() => mockPosition.accuracy).thenReturn(3.5);
      when(() => mockPosition.altitudeAccuracy).thenReturn(1.2);
      when(() => mockPosition.speed).thenReturn(0.8);
      when(() => mockPosition.timestamp).thenReturn(DateTime.parse(timestamp));

      final reading = GpsReading.fromPosition(mockPosition);

      expect(reading.latitude, 4.7110);
      expect(reading.longitude, -74.0721);
      expect(reading.altitude, 2600.0);
      expect(reading.horizontalAccuracy, 3.5);
      expect(reading.altitudeAccuracy, 1.2);
      expect(reading.speed, 0.8);
      expect(reading.timestamp, DateTime.parse(timestamp));
    });

    test('maneja campos opcionales nulos (speed, altitudeAccuracy)', () {
      when(() => mockPosition.latitude).thenReturn(4.7110);
      when(() => mockPosition.longitude).thenReturn(-74.0721);
      when(() => mockPosition.altitude).thenReturn(2600.0);
      when(() => mockPosition.accuracy).thenReturn(5.0);
      when(() => mockPosition.altitudeAccuracy).thenReturn(0.0);
      when(() => mockPosition.speed).thenReturn(0.0);
      when(() => mockPosition.timestamp)
          .thenReturn(DateTime(2026, 3, 15, 10, 30));

      final reading = GpsReading.fromPosition(mockPosition);

      expect(reading.latitude, 4.7110);
      expect(reading.longitude, -74.0721);
      expect(reading.altitude, 2600.0);
      expect(reading.horizontalAccuracy, 5.0);
      expect(reading.altitudeAccuracy, 0.0);
      expect(reading.speed, 0.0);
      expect(reading.timestamp, isNotNull);
    });
  });

  group('GpsReading.copyWith', () {
    test('crea una nueva instancia con campos actualizados', () {
      final original = GpsReading(
        latitude: 4.7110,
        longitude: -74.0721,
        altitude: 2600.0,
        horizontalAccuracy: 3.5,
        altitudeAccuracy: 1.2,
        speed: 0.8,
        timestamp: DateTime(2026, 3, 15, 10, 30),
      );

      final updated = original.copyWith(
        latitude: 5.0,
        speed: 1.5,
      );

      expect(updated.latitude, 5.0);
      expect(updated.longitude, -74.0721);
      expect(updated.altitude, 2600.0);
      expect(updated.horizontalAccuracy, 3.5);
      expect(updated.altitudeAccuracy, 1.2);
      expect(updated.speed, 1.5);
      expect(updated.timestamp, DateTime(2026, 3, 15, 10, 30));
      expect(identical(original, updated), isFalse);
    });

    test('mantiene todos los campos cuando no se pasan argumentos', () {
      final original = GpsReading(
        latitude: 4.7110,
        longitude: -74.0721,
        altitude: 2600.0,
        horizontalAccuracy: 3.5,
        altitudeAccuracy: 1.2,
        speed: 0.8,
        timestamp: DateTime(2026, 3, 15, 10, 30),
      );

      final copy = original.copyWith();

      expect(copy, equals(original));
      expect(identical(original, copy), isFalse);
    });
  });

  group('GpsReading equality', () {
    test('dos GpsReading con los mismos valores son iguales', () {
      final reading1 = GpsReading(
        latitude: 4.7110,
        longitude: -74.0721,
        altitude: 2600.0,
        horizontalAccuracy: 3.5,
        altitudeAccuracy: 1.2,
        speed: 0.8,
        timestamp: DateTime(2026, 3, 15, 10, 30),
      );

      final reading2 = GpsReading(
        latitude: 4.7110,
        longitude: -74.0721,
        altitude: 2600.0,
        horizontalAccuracy: 3.5,
        altitudeAccuracy: 1.2,
        speed: 0.8,
        timestamp: DateTime(2026, 3, 15, 10, 30),
      );

      expect(reading1, equals(reading2));
      expect(reading1.hashCode, reading2.hashCode);
    });

    test('dos GpsReading con valores diferentes no son iguales', () {
      final reading1 = GpsReading(
        latitude: 4.7110,
        longitude: -74.0721,
        altitude: 2600.0,
        horizontalAccuracy: 3.5,
        altitudeAccuracy: 1.2,
        speed: 0.8,
        timestamp: DateTime(2026, 3, 15, 10, 30),
      );

      final reading2 = GpsReading(
        latitude: 5.0,
        longitude: -74.0721,
        altitude: 2600.0,
        horizontalAccuracy: 3.5,
        altitudeAccuracy: 1.2,
        speed: 0.8,
        timestamp: DateTime(2026, 3, 15, 10, 30),
      );

      expect(reading1, isNot(equals(reading2)));
    });
  });

  group('GpsReading.toString', () {
    test('contiene los campos clave', () {
      final reading = GpsReading(
        latitude: 4.7110,
        longitude: -74.0721,
        altitude: 2600.0,
        horizontalAccuracy: 3.5,
        altitudeAccuracy: 1.2,
        speed: 0.8,
        timestamp: DateTime(2026, 3, 15, 10, 30),
      );

      final str = reading.toString();

      expect(str, contains('4.711'));
      expect(str, contains('-74.0721'));
      expect(str, contains('2600.0'));
      expect(str, contains('3.5'));
      expect(str, contains('1.2'));
      expect(str, contains('0.8'));
      expect(str, contains('GpsReading'));
    });
  });
}
