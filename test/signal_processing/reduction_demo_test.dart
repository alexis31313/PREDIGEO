import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:predigeo/core/utils/geo_utils.dart';
import 'package:predigeo/domain/entities/gps_reading.dart';
import 'package:predigeo/domain/usecases/signal_processing/outlier_filter.dart';
import 'package:predigeo/domain/usecases/signal_processing/weighted_averager.dart';

void main() {
  final trueLat = 4.7110;
  final trueLon = -74.0721;
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

  List<GpsReading> generateNoisyReadings({
    required int count,
    required double noiseMeters,
    int seed = 42,
  }) {
    final random = Random(seed);
    final readings = <GpsReading>[];

    for (int i = 0; i < count; i++) {
      final latNoise = (random.nextDouble() - 0.5) * 2 * noiseMeters / 111320.0;
      final lonNoise = (random.nextDouble() - 0.5) *
          2 *
          noiseMeters /
          (111320.0 * cos(trueLat * pi / 180.0));

      readings.add(makeReading(
        lat: trueLat + latNoise,
        lon: trueLon + lonNoise,
        accuracy: noiseMeters / 2,
        secondsOffset: i,
      ));
    }

    return readings;
  }

  double calculateAverageError(List<GpsReading> readings) {
    if (readings.isEmpty) return double.infinity;

    double totalError = 0.0;
    for (final reading in readings) {
      totalError += GeoUtils.haversineDistance(
        reading.latitude,
        reading.longitude,
        trueLat,
        trueLon,
      );
    }
    return totalError / readings.length;
  }

  group('Error Reduction Integration', () {
    test('filtered error is less than raw error (±5m noise)', () {
      final readings = generateNoisyReadings(count: 100, noiseMeters: 5.0);

      final rawError = calculateAverageError(readings);

      final filter = OutlierFilter(maxAccuracy: 20.0, maxSpeed: 15.0);
      final filtered = filter.filter(readings);

      final averager = WeightedAverager();
      final averaged = averager.average(filtered);

      final filteredError = GeoUtils.haversineDistance(
        averaged.latitude,
        averaged.longitude,
        trueLat,
        trueLon,
      );

      expect(filteredError, lessThan(rawError));
    });

    test('error reduction with ±2m noise', () {
      final readings =
          generateNoisyReadings(count: 100, noiseMeters: 2.0, seed: 1);

      final rawError = calculateAverageError(readings);

      final filter = OutlierFilter(maxAccuracy: 20.0, maxSpeed: 15.0);
      final filtered = filter.filter(readings);

      final averager = WeightedAverager();
      final averaged = averager.average(filtered);

      final filteredError = GeoUtils.haversineDistance(
        averaged.latitude,
        averaged.longitude,
        trueLat,
        trueLon,
      );

      expect(filteredError, lessThan(rawError));
    });

    test('error reduction with ±5m noise', () {
      final readings =
          generateNoisyReadings(count: 100, noiseMeters: 5.0, seed: 2);

      final rawError = calculateAverageError(readings);

      final filter = OutlierFilter(maxAccuracy: 20.0, maxSpeed: 15.0);
      final filtered = filter.filter(readings);

      final averager = WeightedAverager();
      final averaged = averager.average(filtered);

      final filteredError = GeoUtils.haversineDistance(
        averaged.latitude,
        averaged.longitude,
        trueLat,
        trueLon,
      );

      expect(filteredError, lessThan(rawError));
    });

    test('error reduction with ±10m noise', () {
      final readings =
          generateNoisyReadings(count: 100, noiseMeters: 10.0, seed: 3);

      final rawError = calculateAverageError(readings);

      final filter = OutlierFilter(maxAccuracy: 20.0, maxSpeed: 15.0);
      final filtered = filter.filter(readings);

      final averager = WeightedAverager();
      final averaged = averager.average(filtered);

      final filteredError = GeoUtils.haversineDistance(
        averaged.latitude,
        averaged.longitude,
        trueLat,
        trueLon,
      );

      expect(filteredError, lessThan(rawError));
    });

    test('edge case: all readings filtered throws exception', () {
      final readings = List.generate(
        10,
        (i) => makeReading(
          lat: 4.8000 + i * 0.01,
          lon: -74.2000 + i * 0.01,
          accuracy: 50.0,
          secondsOffset: i,
        ),
      );

      final filter = OutlierFilter(maxAccuracy: 10.0);
      final filtered = filter.filter(readings);

      expect(filtered, isEmpty);

      final averager = WeightedAverager();
      expect(
        () => averager.average(filtered),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('edge case: insufficient samples throws exception', () {
      final readings =
          generateNoisyReadings(count: 3, noiseMeters: 5.0, seed: 4);

      final filter = OutlierFilter(maxAccuracy: 1.0);
      final filtered = filter.filter(readings);

      expect(filtered.length, lessThan(3));

      if (filtered.isEmpty) {
        final averager = WeightedAverager();
        expect(
          () => averager.average(filtered),
          throwsA(isA<ArgumentError>()),
        );
      }
    });
  });
}
