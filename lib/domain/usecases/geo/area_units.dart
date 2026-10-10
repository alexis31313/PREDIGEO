import 'package:intl/intl.dart';

class AreaUnits {
  static double toHectares(double m2) => m2 / 10000.0;

  static double toFanegadas(double m2) => m2 / 6400.0;

  static double toPlazas(double m2) => m2 / 6400.0;

  static double toCuadras(double m2) => m2 / 6400.0;

  static double toSquareMeters(double m2) => m2;

  static String formatArea(double m2) {
    final fmt = NumberFormat('#,##0.00', 'es_CO');
    final m2Str = fmt.format(m2);
    final haStr = fmt.format(toHectares(m2));
    return '$m2Str m² ($haStr ha)';
  }

  static String formatAreaWithUnit(double m2, String unit) {
    final fmt = NumberFormat('#,##0.00', 'es_CO');
    double value;
    switch (unit.toLowerCase()) {
      case 'ha':
      case 'hectarea':
      case 'hectareas':
        value = toHectares(m2);
        break;
      case 'fanegada':
      case 'fanegadas':
        value = toFanegadas(m2);
        break;
      case 'plaza':
      case 'plazas':
        value = toPlazas(m2);
        break;
      case 'cuadra':
      case 'cuadras':
        value = toCuadras(m2);
        break;
      case 'm2':
      case 'm²':
      case 'metro':
      case 'metros':
      default:
        value = m2;
        unit = 'm²';
        break;
    }
    return '${fmt.format(value)} $unit';
  }
}
