import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:predigeo/domain/entities/gps_reading.dart';
import 'package:predigeo/domain/usecases/signal_processing/simple_kalman_filter.dart';

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

  group('SimpleKalmanFilter2D', () {
    test('filter reduces noise from known point', () {
      final filter = SimpleKalmanFilter2D(processNoise: 0.01);
      final trueLat = 4.7110;
      final trueLon = -74.0721;
      final random = Random(42);

      GpsReading? result;
      for (int i = 0; i < 50; i++) {
        final noisyReading = makeReading(
          lat: trueLat + random.nextDouble() * 0.0002 - 0.0001,
          lon: trueLon + random.nextDouble() * 0.0002 - 0.0001,
          accuracy: 5.0,
          secondsOffset: i,
        );
        result = filter.update(noisyReading);
      }

      final errorLat = (result!.latitude - trueLat).abs();
      final errorLon = (result.longitude - trueLon).abs();
      expect(errorLat, lessThan(0.0001));
      expect(errorLon, lessThan(0.0001));
    });

    test('reset clears state', () {
      final filter = SimpleKalmanFilter2D(processNoise: 0.01);

      for (int i = 0; i < 10; i++) {
        filter.update(makeReading(
          lat: 4.7200,
          lon: -74.0800,
          secondsOffset: i,
        ));
      }

      filter.reset();

      final reading = makeReading(
        lat: 4.7110,
        lon: -74.0721,
        secondsOffset: 100,
      );
      final result = filter.update(reading);

      expect(result.latitude, closeTo(4.7110, 0.001));
      expect(result.longitude, closeTo(-74.0721, 0.001));
    });

    test('multiple updates converge toward true value', () {
      final filter = SimpleKalmanFilter2D(processNoise: 0.01);
      final trueLat = 4.7110;
      final trueLon = -74.0721;
      final random = Random(123);

      double prevError = double.infinity;
      for (int i = 0; i < 30; i++) {
        final noisyReading = makeReading(
          lat: trueLat + random.nextDouble() * 0.0004 - 0.0002,
          lon: trueLon + random.nextDouble() * 0.0004 - 0.0002,
          accuracy: 5.0,
          secondsOffset: i,
        );
        final result = filter.update(noisyReading);

        final currentError = sqrt(
          pow(result.latitude - trueLat, 2) +
              pow(result.longitude - trueLon, 2),
        );

        if (i > 5) {
          expect(currentError, lessThan(prevError * 1.5));
        }
        prevError = currentError;
      }
    });

    test('filter with single reading returns that reading', () {
      final filter = SimpleKalmanFilter2D(processNoise: 0.01);
      final reading = makeReading(lat: 4.7110, lon: -74.0721, accuracy: 5.0);

      final result = filter.update(reading);

      expect(result.latitude, closeTo(4.7110, 0.001));
      expect(result.longitude, closeTo(-74.0721, 0.001));
    });

    test('processNoise parameter affects smoothing', () {
      final trueLat = 4.7110;
      final trueLon = -74.0721;
      final random = Random(42);

      final lowNoiseFilter = SimpleKalmanFilter2D(processNoise: 0.001);
      final highNoiseFilter = SimpleKalmanFilter2D(processNoise: 0.1);

      double lowNoiseError = 0;
      double highNoiseError = 0;

      for (int i = 0; i < 30; i++) {
        final noisyReading = makeReading(
          lat: trueLat + random.nextDouble() * 0.0002 - 0.0001,
          lon: trueLon + random.nextDouble() * 0.0002 - 0.0001,
          accuracy: 5.0,
          secondsOffset: i,
        );

        final lowResult = lowNoiseFilter.update(noisyReading);
        final highResult = highNoiseFilter.update(noisyReading);

        lowNoiseError += sqrt(
          pow(lowResult.latitude - trueLat, 2) +
              pow(lowResult.longitude - trueLon, 2),
        );
        highNoiseError += sqrt(
          pow(highResult.latitude - trueLat, 2) +
              pow(highResult.longitude - trueLon, 2),
        );
      }

      expect(lowNoiseError, isNot(equals(highNoiseError)));
    });
  });
}
