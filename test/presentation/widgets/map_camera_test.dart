import 'package:flutter_test/flutter_test.dart';
import 'package:predigeo/domain/entities/geo_point.dart';
import 'package:predigeo/presentation/widgets/measurement_map_view.dart';

void main() {
  GeoPoint point(double lat, double lng, {int seq = 0}) => GeoPoint(
        seq: seq,
        latitude: lat,
        longitude: lng,
        altitude: 0,
        accuracy: 4,
        timestamp: DateTime(2026, 3, 15),
      );

  group('MapCamera.center', () {
    test('promedia latitud y longitud', () {
      final center = MapCamera.center([
        point(1.0, -76.0),
        point(3.0, -74.0),
      ]);

      expect(center.latitude, closeTo(2.0, 1e-9));
      expect(center.longitude, closeTo(-75.0, 1e-9));
    });

    test('lista vacía devuelve el origen', () {
      final center = MapCamera.center(const []);
      expect(center.latitude, 0);
      expect(center.longitude, 0);
    });
  });

  group('MapCamera.zoom', () {
    test('un solo punto usa un zoom cercano', () {
      expect(MapCamera.zoom([point(1.15, -76.65)]), 17.0);
    });

    test('un área grande usa menos zoom que una pequeña', () {
      final large = MapCamera.zoom([
        point(0, -74),
        point(5, -69),
      ]);
      final small = MapCamera.zoom([
        point(1.15380, -76.65100),
        point(1.15390, -76.65090),
      ]);

      expect(small, greaterThan(large));
      expect(large, greaterThanOrEqualTo(3.0));
      expect(small, lessThanOrEqualTo(20.0));
    });

    test('puntos idénticos no producen infinito', () {
      final zoom = MapCamera.zoom([
        point(1.15, -76.65),
        point(1.15, -76.65),
      ]);
      expect(zoom, 17.0);
    });
  });
}
