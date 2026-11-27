import 'package:flutter_test/flutter_test.dart';
import 'package:predigeo/domain/usecases/geo/altitude_fusion.dart';

void main() {
  group('barometricAltitude', () {
    test('es 0 a la presión estándar y crece al bajar la presión', () {
      expect(barometricAltitude(1013.25), closeTo(0, 1e-9));
      expect(barometricAltitude(900), greaterThan(900));
    });

    test('~0.12 hPa equivalen a ~1 m cerca del nivel del mar', () {
      final dh = barometricAltitude(1000.0) - barometricAltitude(1000.12);
      expect(dh, closeTo(1.0, 0.1));
    });
  });

  group('fuseAltitudes', () {
    test('sin barómetro devuelve las altitudes GPS', () {
      expect(
        fuseAltitudes([430, 445, 420], [null, null, null]),
        [430, 445, 420],
      );
      expect(fuseAltitudes([430, 445], [1000, null]), [430, 445]);
    });

    test('usa la forma del barómetro y el nivel del GPS', () {
      // Relieve real: 0, +2 m, +4 m. El GPS tiene ruido de ±8 m.
      const p0 = 960.0;
      final pressures = <double?>[
        p0,
        p0 - 2 * 0.113, // ~2 m más alto
        p0 - 4 * 0.113, // ~4 m más alto
      ];
      final gps = <double>[438, 425, 436];
      final fused = fuseAltitudes(gps, pressures);

      expect(fused[1] - fused[0], closeTo(2, 0.3));
      expect(fused[2] - fused[0], closeTo(4, 0.3));
      // El nivel medio queda cerca del GPS (mediana de las diferencias).
      final meanFused = fused.reduce((a, b) => a + b) / 3;
      expect(meanFused, closeTo(433, 6));
    });

    test('los puntos sin presión conservan su altitud GPS', () {
      final fused = fuseAltitudes([430, 431, 500], [960, 959.9, null]);
      expect(fused[2], 500);
    });
  });
}
