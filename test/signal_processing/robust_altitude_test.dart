import 'package:flutter_test/flutter_test.dart';
import 'package:predigeo/domain/entities/gps_reading.dart';
import 'package:predigeo/domain/usecases/signal_processing/weighted_averager.dart';

void main() {
  GpsReading reading(double altitude, {double vAcc = 4, double hAcc = 5}) =>
      GpsReading(
        latitude: 1.1538,
        longitude: -76.651,
        altitude: altitude,
        horizontalAccuracy: hAcc,
        altitudeAccuracy: vAcc,
        speed: 0,
        timestamp: DateTime(2026, 3, 15),
      );

  test('descarta altitudes atípicas con la mediana', () {
    final readings = [
      reading(430),
      reading(431),
      reading(429.5),
      reading(430.5),
      reading(470), // salto típico del GPS
    ];

    final result = const WeightedAverager().average(readings);

    expect(result.altitude, closeTo(430.25, 0.01));
  });

  test('pondera la altitud con la precisión vertical', () {
    final (altitude, accuracy) = WeightedAverager.robustAltitude([
      reading(430, vAcc: 1),
      reading(434, vAcc: 10),
    ]);

    expect(altitude, lessThan(430.1));
    expect(accuracy, isNotNull);
    expect(accuracy!, lessThan(1));
  });

  test('sin precisión vertical usa la horizontal', () {
    final (altitude, accuracy) = WeightedAverager.robustAltitude([
      reading(430, vAcc: 0, hAcc: 2),
      reading(436, vAcc: 0, hAcc: 20),
    ]);

    expect(altitude, closeTo(430.06, 0.01));
    expect(accuracy, isNull);
  });
}
