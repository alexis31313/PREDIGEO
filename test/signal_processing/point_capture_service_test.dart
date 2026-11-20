import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:predigeo/data/datasources/location_service.dart';
import 'package:predigeo/domain/entities/gps_reading.dart';
import 'package:predigeo/domain/usecases/signal_processing/captured_point.dart';
import 'package:predigeo/domain/usecases/signal_processing/outlier_filter.dart';
import 'package:predigeo/domain/usecases/signal_processing/point_capture_service.dart';

class MockLocationService extends Mock implements LocationService {}

void main() {
  final baseTime = DateTime(2026, 3, 15, 10, 30, 0);

  GpsReading makeReading({
    double lat = 4.7110,
    double lon = -74.0721,
    double accuracy = 5.0,
    int secondsOffset = 0,
  }) {
    return GpsReading(
      latitude: lat,
      longitude: lon,
      altitude: 2600.0,
      horizontalAccuracy: accuracy,
      altitudeAccuracy: 1.0,
      speed: 0.0,
      timestamp: baseTime.add(Duration(seconds: secondsOffset)),
    );
  }

  late MockLocationService mockLocationService;

  setUp(() {
    mockLocationService = MockLocationService();
  });

  /// Configura el mock para devolver las lecturas de [readings] en secuencia.
  /// Una vez agotadas, repite la última.
  void stubReadings(List<GpsReading> readings) {
    var index = 0;
    when(() => mockLocationService.getCurrentReading()).thenAnswer((_) async {
      final reading = readings[index.clamp(0, readings.length - 1)];
      if (index < readings.length - 1) index++;
      return reading;
    });
  }

  group('PointCaptureService.capturePoint', () {
    test('returns CapturedPoint with correct sample count', () async {
      final readings = List.generate(
        10,
        (i) => makeReading(
          lat: 4.7110 + i * 0.00001,
          lon: -74.0721 + i * 0.00001,
          accuracy: 5.0,
          secondsOffset: i,
        ),
      );

      stubReadings(readings);

      final service = PointCaptureService(
        locationService: mockLocationService,
      );

      final result = await service.capturePoint(samples: 5);

      expect(result, isA<CapturedPoint>());
      expect(result.sampleCount, 5);
      expect(result.latitude, closeTo(4.7110, 0.001));
      expect(result.longitude, closeTo(-74.0721, 0.001));
    });

    test('throws InsufficientSamplesException when not enough valid samples',
        () async {
      final readings = [
        makeReading(accuracy: 50.0, secondsOffset: 0),
        makeReading(accuracy: 60.0, secondsOffset: 1),
      ];

      stubReadings(readings);

      final service = PointCaptureService(
        locationService: mockLocationService,
      );

      await expectLater(
        service.capturePoint(samples: 5, timeout: const Duration(seconds: 2)),
        throwsA(isA<InsufficientSamplesException>()),
      );
    });

    test('emits progress callback', () async {
      final readings = List.generate(
        10,
        (i) => makeReading(
          lat: 4.7110 + i * 0.00001,
          lon: -74.0721 + i * 0.00001,
          accuracy: 5.0,
          secondsOffset: i,
        ),
      );

      stubReadings(readings);

      final service = PointCaptureService(
        locationService: mockLocationService,
      );

      final progressValues = <double>[];
      await service.capturePoint(
        samples: 5,
        onProgress: (progress) => progressValues.add(progress),
      );

      expect(progressValues, isNotEmpty);
      expect(progressValues.last, 1.0);
    });

    test('respects timeout', () async {
      stubReadings([makeReading()]);

      final service = PointCaptureService(
        locationService: mockLocationService,
      );

      expect(
        () => service.capturePoint(
          samples: 50,
          timeout: const Duration(milliseconds: 200),
        ),
        throwsA(isA<InsufficientSamplesException>()),
      );
    });

    test('applies outlier filter', () async {
      final readings = [
        makeReading(
            lat: 4.71100, lon: -74.07210, accuracy: 5.0, secondsOffset: 0),
        makeReading(
            lat: 4.71101, lon: -74.07211, accuracy: 5.0, secondsOffset: 1),
        makeReading(
            lat: 4.80000, lon: -74.20000, accuracy: 50.0, secondsOffset: 2),
        makeReading(
            lat: 4.71102, lon: -74.07212, accuracy: 5.0, secondsOffset: 3),
        makeReading(
            lat: 4.71103, lon: -74.07213, accuracy: 5.0, secondsOffset: 4),
      ];

      stubReadings(readings);

      final service = PointCaptureService(
        locationService: mockLocationService,
        outlierFilter: OutlierFilter(maxAccuracy: 20.0),
      );

      final result = await service.capturePoint(
        samples: 3,
        timeout: const Duration(seconds: 5),
      );

      expect(result.latitude, closeTo(4.7111, 0.001));
      expect(result.longitude, closeTo(-74.0722, 0.001));
    });
  });
}
