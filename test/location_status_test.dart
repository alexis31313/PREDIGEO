// Pruebas de la clase sellada LocationStatus.
// Verifica el pattern matching con when() y la estructura de los estados.

import 'package:flutter_test/flutter_test.dart';
import 'package:predigeo/domain/entities/gps_reading.dart';
import 'package:predigeo/domain/entities/location_status.dart';

void main() {
  group('LocationStatus.when', () {
    test('PermissionDenied ejecuta el callback correspondiente', () {
      const status = PermissionDenied(message: 'Permiso denegado');

      final result = status.when(
        permissionDenied: (s) => 'denied: ${s.message}',
        serviceDisabled: (s) => 'disabled',
        acquiring: (s) => 'acquiring',
        ready: (s) => 'ready',
      );

      expect(result, 'denied: Permiso denegado');
    });

    test('ServiceDisabled ejecuta el callback correspondiente', () {
      const status = ServiceDisabled(message: 'Servicio deshabilitado');

      final result = status.when(
        permissionDenied: (s) => 'denied',
        serviceDisabled: (s) => 'disabled: ${s.message}',
        acquiring: (s) => 'acquiring',
        ready: (s) => 'ready',
      );

      expect(result, 'disabled: Servicio deshabilitado');
    });

    test('Acquiring ejecuta el callback correspondiente', () {
      const status = Acquiring(message: 'Buscando ubicación');

      final result = status.when(
        permissionDenied: (s) => 'denied',
        serviceDisabled: (s) => 'disabled',
        acquiring: (s) => 'acquiring: ${s.message}',
        ready: (s) => 'ready',
      );

      expect(result, 'acquiring: Buscando ubicación');
    });

    test('Ready ejecuta el callback correspondiente', () {
      final reading = GpsReading(
        latitude: 4.7110,
        longitude: -74.0721,
        altitude: 2600.0,
        horizontalAccuracy: 3.5,
        altitudeAccuracy: 1.2,
        speed: 0.8,
        timestamp: DateTime(2026, 3, 15, 10, 30),
      );
      final status = Ready(reading: reading);

      final result = status.when(
        permissionDenied: (s) => 'denied',
        serviceDisabled: (s) => 'disabled',
        acquiring: (s) => 'acquiring',
        ready: (s) => 'ready: ${s.reading?.latitude}',
      );

      expect(result, 'ready: 4.711');
    });
  });

  group('LocationStatus types', () {
    test('los cuatro estados son tipos diferentes', () {
      const denied = PermissionDenied();
      const disabled = ServiceDisabled();
      const acquiring = Acquiring();
      const ready = Ready();

      expect(denied, isNot(isA<ServiceDisabled>()));
      expect(denied, isNot(isA<Acquiring>()));
      expect(denied, isNot(isA<Ready>()));
      expect(disabled, isNot(isA<PermissionDenied>()));
      expect(disabled, isNot(isA<Acquiring>()));
      expect(disabled, isNot(isA<Ready>()));
      expect(acquiring, isNot(isA<PermissionDenied>()));
      expect(acquiring, isNot(isA<ServiceDisabled>()));
      expect(acquiring, isNot(isA<Ready>()));
      expect(ready, isNot(isA<PermissionDenied>()));
      expect(ready, isNot(isA<ServiceDisabled>()));
      expect(ready, isNot(isA<Acquiring>()));
    });

    test('todos son subtipos de LocationStatus', () {
      const denied = PermissionDenied();
      const disabled = ServiceDisabled();
      const acquiring = Acquiring();
      const ready = Ready();

      expect(denied, isA<LocationStatus>());
      expect(disabled, isA<LocationStatus>());
      expect(acquiring, isA<LocationStatus>());
      expect(ready, isA<LocationStatus>());
    });
  });

  group('LocationStatus.Ready', () {
    test('contiene un GpsReading', () {
      final reading = GpsReading(
        latitude: 4.7110,
        longitude: -74.0721,
        altitude: 2600.0,
        horizontalAccuracy: 3.5,
        altitudeAccuracy: 1.2,
        speed: 0.8,
        timestamp: DateTime(2026, 3, 15, 10, 30),
      );
      final status = Ready(reading: reading);

      expect(status.reading, isNotNull);
      expect(status.reading!.latitude, 4.7110);
      expect(status.reading!.longitude, -74.0721);
      expect(status.reading!.altitude, 2600.0);
      expect(status.reading!.horizontalAccuracy, 3.5);
      expect(status.reading!.altitudeAccuracy, 1.2);
      expect(status.reading!.speed, 0.8);
      expect(status.reading!.timestamp, DateTime(2026, 3, 15, 10, 30));
    });

    test('puede crearse sin reading', () {
      const status = Ready();

      expect(status.reading, isNull);
    });
  });
}
