// Pruebas de la corrección por relieve: distancias 3D, factor de pendiente,
// área sobre el terreno y desniveles. Valores verificables a mano.

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:predigeo/domain/entities/geo_point.dart';
import 'package:predigeo/domain/usecases/geo/distance_calculator.dart';
import 'package:predigeo/domain/usecases/geo/slope_correction.dart';

void main() {
  final baseTime = DateTime(2026, 3, 15, 10, 30);

  GeoPoint point(double lat, double lon, double alt, [int seq = 0]) {
    return GeoPoint(
      seq: seq,
      latitude: lat,
      longitude: lon,
      altitude: alt,
      accuracy: 5.0,
      timestamp: baseTime,
    );
  }

  group('DistanceCalculator 3D', () {
    test('tramo 3-4-5: horizontal 4 m y Δh 3 m → 5 m', () {
      expect(DistanceCalculator.segmentSlopeLength(4, 0, 3), closeTo(5, 1e-9));
    });

    test('terreno plano: 3D igual a horizontal', () {
      final points = [
        point(1.15, -76.65, 500.0, 0),
        point(1.151, -76.65, 500.0, 1),
        point(1.152, -76.65, 500.0, 2),
      ];
      expect(
        DistanceCalculator.pathLength3D(points),
        closeTo(DistanceCalculator.pathLength(points), 1e-6),
      );
    });

    test('3D siempre >= horizontal', () {
      final points = [
        point(1.15, -76.65, 500.0, 0),
        point(1.151, -76.651, 520.0, 1),
        point(1.152, -76.65, 505.0, 2),
      ];
      expect(
        DistanceCalculator.pathLength3D(points),
        greaterThanOrEqualTo(DistanceCalculator.pathLength(points)),
      );
    });

    test('perímetro 3D cierra el polígono', () {
      const lat = 1.15;
      const lon = -76.65;
      final points = [
        point(lat, lon, 500.0, 0),
        point(lat, lon + 0.001, 510.0, 1),
        point(lat + 0.001, lon + 0.001, 505.0, 2),
        point(lat + 0.001, lon, 500.0, 3),
      ];
      expect(
        DistanceCalculator.perimeter3D(points),
        greaterThan(DistanceCalculator.perimeter(points)),
      );
    });

    test('con 0 o 1 punto → 0', () {
      expect(DistanceCalculator.pathLength3D([]), 0);
      expect(DistanceCalculator.perimeter3D([point(1.15, -76.65, 500.0)]), 0);
    });
  });

  group('SlopeCorrection', () {
    test('terreno plano: factor 1 y pendiente 0', () {
      final points = [
        point(1.15, -76.65, 500.0, 0),
        point(1.151, -76.65, 500.0, 1),
        point(1.152, -76.65, 500.0, 2),
      ];
      expect(SlopeCorrection.meanSlopeRadians(points), closeTo(0, 1e-9));
      expect(SlopeCorrection.slopeFactor(points), closeTo(1, 1e-9));
      expect(SlopeCorrection.slopedArea(10000, points), closeTo(10000, 1e-6));
      expect(SlopeCorrection.isFlat(points), isTrue);
    });

    test('pendiente 45° (Δh 10 m en 10 m): factor √2', () {
      // 10 m horizontales ≈ 10 / 111194.9 grados de latitud.
      const side = 10.0 / 111194.9;
      final points = [
        point(0, 0, 0, 0),
        point(side, 0, 10.0, 1),
      ];
      expect(
        SlopeCorrection.meanSlopeRadians(points, closed: false),
        closeTo(math.pi / 4, 0.01),
      );
      expect(
        SlopeCorrection.slopeFactor(points, closed: false),
        closeTo(math.sqrt2, 0.01),
      );
    });

    test('área sobre el terreno >= planimétrica', () {
      final points = [
        point(1.15, -76.65, 500.0, 0),
        point(1.151, -76.65, 515.0, 1),
        point(1.151, -76.651, 505.0, 2),
      ];
      expect(
        SlopeCorrection.slopedArea(10000, points),
        greaterThanOrEqualTo(10000),
      );
    });

    test('desnivel: subida 10 m y bajada 2 m', () {
      final points = [
        point(1.15, -76.65, 500.0, 0),
        point(1.151, -76.65, 505.0, 1),
        point(1.152, -76.65, 503.0, 2),
        point(1.153, -76.65, 508.0, 3),
      ];
      final result = SlopeCorrection.elevationGainLoss(points);
      expect(result.gain, closeTo(10.0, 1e-9));
      expect(result.loss, closeTo(2.0, 1e-9));
      expect(SlopeCorrection.altitudeRange(points), closeTo(8.0, 1e-9));
      expect(SlopeCorrection.isFlat(points), isFalse);
    });

    test('sin puntos: rango 0 y plano', () {
      expect(SlopeCorrection.altitudeRange([]), 0);
      expect(SlopeCorrection.isFlat([]), isTrue);
      final result = SlopeCorrection.elevationGainLoss([]);
      expect(result.gain, 0);
      expect(result.loss, 0);
    });
  });
}
