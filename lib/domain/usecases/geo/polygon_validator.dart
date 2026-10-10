import '../../entities/geo_point.dart';

class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });
}

class PolygonValidator {
  static const double _epsilon = 1e-9;

  ValidationResult validate(List<GeoPoint> points) {
    final errors = <String>[];
    final warnings = <String>[];

    if (points.length < 3) {
      errors.add('Se requieren al menos 3 puntos para formar un polígono.');
      return ValidationResult(isValid: false, errors: errors);
    }

    final duplicates = _findConsecutiveDuplicates(points);
    if (duplicates.isNotEmpty) {
      errors.add('Puntos duplicados consecutivos en las posiciones: ${duplicates.join(', ')}.');
    }

    final intersections = _findSelfIntersections(points);
    if (intersections.isNotEmpty) {
      errors.add('Se detectaron ${intersections.length} auto-intersección(es) en el polígono.');
    }

    if (points.length < 4) {
      warnings.add('El polígono tiene menos de 4 lados. Verifique la medición.');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  List<int> _findConsecutiveDuplicates(List<GeoPoint> points) {
    final duplicates = <int>[];
    for (int i = 0; i < points.length; i++) {
      final next = (i + 1) % points.length;
      if (_pointsEqual(points[i], points[next])) {
        duplicates.add(next);
      }
    }
    return duplicates;
  }

  bool _pointsEqual(GeoPoint a, GeoPoint b) {
    return (a.latitude - b.latitude).abs() < _epsilon &&
        (a.longitude - b.longitude).abs() < _epsilon;
  }

  List<String> _findSelfIntersections(List<GeoPoint> points) {
    final intersections = <String>[];
    final n = points.length;

    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      for (int k = i + 1; k < n; k++) {
        final l = (k + 1) % n;

        if (_areAdjacent(i, j, k, l, n)) continue;

        final p1 = (points[i].longitude, points[i].latitude);
        final p2 = (points[j].longitude, points[j].latitude);
        final p3 = (points[k].longitude, points[k].latitude);
        final p4 = (points[l].longitude, points[l].latitude);

        if (_segmentsIntersect(p1, p2, p3, p4)) {
          intersections.add('Lado ${i}-${j} cruza con lado ${k}-${l}');
        }
      }
    }
    return intersections;
  }

  bool _areAdjacent(int i, int j, int k, int l, int n) {
    if (i == k || i == l || j == k || j == l) return true;
    if ((i + 1) % n == k || (k + 1) % n == i) return true;
    if ((j + 1) % n == l || (l + 1) % n == j) return true;
    return false;
  }

  bool _segmentsIntersect(
      (double, double) p1, (double, double) p2, (double, double) p3, (double, double) p4) {
    final d1 = _direction(p3, p4, p1);
    final d2 = _direction(p3, p4, p2);
    final d3 = _direction(p1, p2, p3);
    final d4 = _direction(p1, p2, p4);

    if (((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
        ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0))) {
      return true;
    }

    if (d1 == 0 && _onSegment(p3, p4, p1)) return true;
    if (d2 == 0 && _onSegment(p3, p4, p2)) return true;
    if (d3 == 0 && _onSegment(p1, p2, p3)) return true;
    if (d4 == 0 && _onSegment(p1, p2, p4)) return true;

    return false;
  }

  double _direction((double, double) pi, (double, double) pj, (double, double) pk) {
    return (pk.$1 - pi.$1) * (pj.$2 - pi.$2) - (pj.$1 - pi.$1) * (pk.$2 - pi.$2);
  }

  bool _onSegment((double, double) pi, (double, double) pj, (double, double) pk) {
    return (pi.$1 <= pk.$1 && pk.$1 <= pj.$1 && pi.$2 <= pk.$2 && pk.$2 <= pj.$2) ||
        (pi.$1 >= pk.$1 && pk.$1 >= pj.$1 && pi.$2 >= pk.$2 && pk.$2 >= pj.$2);
  }
}
