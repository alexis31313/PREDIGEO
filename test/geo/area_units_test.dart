import 'package:flutter_test/flutter_test.dart';
import 'package:predigeo/domain/usecases/geo/area_units.dart';

void main() {
  group('AreaUnits.toHectares', () {
    test('10000 m² → 1.0 ha', () {
      expect(AreaUnits.toHectares(10000), closeTo(1.0, 1e-9));
    });
  });

  group('AreaUnits.toFanegadas', () {
    test('6400 m² → 1.0 fanegada', () {
      expect(AreaUnits.toFanegadas(6400), closeTo(1.0, 1e-9));
    });
  });

  group('AreaUnits.toPlazas', () {
    test('6400 m² → 1.0 plaza', () {
      expect(AreaUnits.toPlazas(6400), closeTo(1.0, 1e-9));
    });
  });

  group('AreaUnits.toCuadras', () {
    test('6400 m² → 1.0 cuadra', () {
      expect(AreaUnits.toCuadras(6400), closeTo(1.0, 1e-9));
    });
  });

  group('AreaUnits.formatArea', () {
    test('devuelve cadena formateada con 2 decimales', () {
      final formatted = AreaUnits.formatArea(10000);

      expect(formatted, contains('ha'));
      expect(formatted, matches(RegExp(r'\d+[.,]\d{2}')));
    });

    test('formatea valores no exactos con 2 decimales', () {
      expect(AreaUnits.formatArea(12345.6), contains('1,23'));
    });
  });

  group('AreaUnits.formatAreaWithUnit', () {
    test('funciona para todas las unidades', () {
      expect(AreaUnits.formatAreaWithUnit(10000, 'ha'), contains('1,00'));
      expect(AreaUnits.formatAreaWithUnit(6400, 'fanegada'), contains('1,00'));
      expect(AreaUnits.formatAreaWithUnit(6400, 'plaza'), contains('1,00'));
      expect(AreaUnits.formatAreaWithUnit(6400, 'cuadra'), contains('1,00'));
    });

    test('formatea valores no exactos con 2 decimales', () {
      expect(AreaUnits.formatAreaWithUnit(10000, 'fanegada'), contains('1,56'));
    });
  });
}
