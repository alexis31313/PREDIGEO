import 'package:flutter_test/flutter_test.dart';
import 'package:predigeo/domain/entities/gps_reading.dart';
import 'package:predigeo/domain/usecases/signal_processing/weighted_averager.dart';

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

  group('WeightedAverager.average', () {
    test('average of single reading returns same reading', () {
      final averager = WeightedAverager();
      final reading = makeReading(lat: 4.7110, lon: -74.0721, accuracy: 5.0);

      final result = averager.average([reading]);

      expect(result.latitude, closeTo(4.7110, 1e-10));
      expect(result.longitude, closeTo(-74.0721, 1e-10));
      expect(result.altitude, closeTo(2600.0, 1e-10));
    });

    test('average of multiple readings with same accuracy', () {
      final averager = WeightedAverager();
      final readings = [
        makeReading(
            lat: 4.7100, lon: -74.0700, accuracy: 5.0, secondsOffset: 0),
        makeReading(
            lat: 4.7120, lon: -74.0740, accuracy: 5.0, secondsOffset: 1),
      ];

      final result = averager.average(readings);

      expect(result.latitude, closeTo(4.7110, 1e-6));
      expect(result.longitude, closeTo(-74.0720, 1e-6));
    });

    test('weighted average favors more accurate readings', () {
      final averager = WeightedAverager();
      final readings = [
        makeReading(
            lat: 4.7100, lon: -74.0700, accuracy: 10.0, secondsOffset: 0),
        makeReading(
            lat: 4.7120, lon: -74.0740, accuracy: 2.0, secondsOffset: 1),
      ];

      final result = averager.average(readings);

      expect(result.latitude, greaterThan(4.7110));
      expect(result.longitude, lessThan(-74.0720));
    });

    test('estimated accuracy is better than worst input', () {
      final averager = WeightedAverager();
      final readings = [
        makeReading(accuracy: 10.0, secondsOffset: 0),
        makeReading(accuracy: 8.0, secondsOffset: 1),
        makeReading(accuracy: 6.0, secondsOffset: 2),
      ];

      final result = averager.average(readings);

      expect(result.horizontalAccuracy, lessThan(6.0));
    });

    test('throws ArgumentError for empty list', () {
      final averager = WeightedAverager();

      expect(
        () => averager.average([]),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('all zero accuracies uses simple average', () {
      final averager = WeightedAverager();
      final readings = [
        makeReading(
            lat: 4.7100, lon: -74.0700, accuracy: 0.0, secondsOffset: 0),
        makeReading(
            lat: 4.7120, lon: -74.0740, accuracy: 0.0, secondsOffset: 1),
      ];

      final result = averager.average(readings);

      expect(result.latitude, closeTo(4.7110, 1e-10));
      expect(result.longitude, closeTo(-74.0720, 1e-10));
      expect(result.horizontalAccuracy, 0.0);
    });
  });
}
