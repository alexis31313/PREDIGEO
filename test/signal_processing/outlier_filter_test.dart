import 'package:flutter_test/flutter_test.dart';
import 'package:predigeo/domain/entities/gps_reading.dart';
import 'package:predigeo/domain/usecases/signal_processing/outlier_filter.dart';

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

  group('OutlierFilter.filter', () {
    test('removes readings with accuracy above threshold', () {
      final filter = OutlierFilter(maxAccuracy: 10.0);
      final readings = [
        makeReading(accuracy: 5.0, secondsOffset: 0),
        makeReading(accuracy: 25.0, secondsOffset: 1),
        makeReading(accuracy: 8.0, secondsOffset: 2),
      ];

      final result = filter.filter(readings);

      expect(result.length, 2);
      expect(result[0].horizontalAccuracy, 5.0);
      expect(result[1].horizontalAccuracy, 8.0);
    });

    test('removes readings with impossible speed jumps', () {
      final filter = OutlierFilter(maxSpeed: 15.0);
      final readings = [
        makeReading(lat: 4.7110, lon: -74.0721, secondsOffset: 0),
        makeReading(lat: 4.711001, lon: -74.0721, secondsOffset: 1),
        makeReading(lat: 4.711002, lon: -74.0721, secondsOffset: 2),
      ];

      final result = filter.filter(readings);

      expect(result.length, 3);
      expect(result[0].latitude, 4.7110);
      expect(result[2].latitude, 4.711002);
    });

    test('returns empty list when input is empty', () {
      final filter = OutlierFilter();
      final result = filter.filter([]);
      expect(result, isEmpty);
    });

    test('returns all readings when all are valid', () {
      final filter = OutlierFilter(maxAccuracy: 20.0, maxSpeed: 15.0);
      final readings = [
        makeReading(accuracy: 5.0, secondsOffset: 0),
        makeReading(accuracy: 8.0, secondsOffset: 1),
        makeReading(accuracy: 3.0, secondsOffset: 2),
      ];

      final result = filter.filter(readings);

      expect(result.length, 3);
    });

    test('custom maxAccuracy threshold works', () {
      final filter = OutlierFilter(maxAccuracy: 3.0);
      final readings = [
        makeReading(accuracy: 2.0, secondsOffset: 0),
        makeReading(accuracy: 5.0, secondsOffset: 1),
        makeReading(accuracy: 1.0, secondsOffset: 2),
      ];

      final result = filter.filter(readings);

      expect(result.length, 2);
      expect(result[0].horizontalAccuracy, 2.0);
      expect(result[1].horizontalAccuracy, 1.0);
    });

    test('custom maxSpeed threshold works', () {
      final filter = OutlierFilter(maxSpeed: 5.0);
      final readings = [
        makeReading(lat: 4.7110, lon: -74.0721, secondsOffset: 0),
        makeReading(lat: 4.711001, lon: -74.0721, secondsOffset: 1),
        makeReading(lat: 4.71101, lon: -74.0721, secondsOffset: 2),
      ];

      final result = filter.filter(readings);

      expect(result.length, 2);
      expect(result[0].latitude, 4.7110);
      expect(result[1].latitude, 4.711001);
    });
  });

  group('OutlierFilter.filterSingle', () {
    test('returns true for valid reading', () {
      final filter = OutlierFilter();
      final reading = makeReading(accuracy: 5.0);

      final result = filter.filterSingle(reading, null);

      expect(result, isTrue);
    });

    test('returns false for outlier reading', () {
      final filter = OutlierFilter(maxAccuracy: 10.0);
      final reading = makeReading(accuracy: 25.0);

      final result = filter.filterSingle(reading, null);

      expect(result, isFalse);
    });

    test('returns false when speed jump is impossible', () {
      final filter = OutlierFilter(maxSpeed: 10.0);
      final previous = makeReading(lat: 4.7110, lon: -74.0721, secondsOffset: 0);
      final current = makeReading(lat: 4.7200, lon: -74.0721, secondsOffset: 1);

      final result = filter.filterSingle(current, previous);

      expect(result, isFalse);
    });

    test('returns true when speed jump is within limits', () {
      final filter = OutlierFilter(maxSpeed: 15.0);
      final previous = makeReading(lat: 4.7110, lon: -74.0721, secondsOffset: 0);
      final current = makeReading(lat: 4.7111, lon: -74.0721, secondsOffset: 1);

      final result = filter.filterSingle(current, previous);

      expect(result, isTrue);
    });
  });
}
