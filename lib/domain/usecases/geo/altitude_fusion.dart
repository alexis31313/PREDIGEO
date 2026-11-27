// Fusión de la altitud del GPS con la altura relativa del barómetro.

import 'dart:math' as math;

/// Altura barométrica (m) para una presión [pressureHpa] respecto de la
/// presión de referencia [referenceHpa] (fórmula hipsométrica estándar).
double barometricAltitude(double pressureHpa, {double referenceHpa = 1013.25}) {
  return 44330.0 * (1.0 - math.pow(pressureHpa / referenceHpa, 1 / 5.255));
}

/// Combina la altitud GPS y la presión de cada punto de una sesión.
///
/// El barómetro mide muy bien las **diferencias** de altura entre puntos
/// (decímetros), pero no la altitud absoluta; el GPS da la altitud absoluta
/// con ±5–15 m de error en cada punto. La fusión usa la forma del relieve del
/// barómetro y la desplaza para que coincida, en mediana, con la altitud GPS:
///
/// `altitud_i = h_baro(p_i) + mediana(gps_j − h_baro(p_j))`
///
/// Los puntos sin presión conservan su altitud GPS. Con menos de dos puntos
/// con presión no hay relieve barométrico y se devuelven las altitudes GPS.
List<double> fuseAltitudes(
  List<double> gpsAltitudes,
  List<double?> pressuresHpa,
) {
  assert(gpsAltitudes.length == pressuresHpa.length);
  final baro = <int, double>{};
  for (var i = 0; i < pressuresHpa.length; i++) {
    final p = pressuresHpa[i];
    if (p != null && p.isFinite && p > 0) {
      baro[i] = barometricAltitude(p);
    }
  }
  if (baro.length < 2) return List<double>.of(gpsAltitudes);

  final offsets = <double>[
    for (final entry in baro.entries)
      if (gpsAltitudes[entry.key].isFinite)
        gpsAltitudes[entry.key] - entry.value,
  ]..sort();
  if (offsets.isEmpty) return List<double>.of(gpsAltitudes);
  final mid = offsets.length ~/ 2;
  final offset = offsets.length.isOdd
      ? offsets[mid]
      : (offsets[mid - 1] + offsets[mid]) / 2;

  return <double>[
    for (var i = 0; i < gpsAltitudes.length; i++)
      baro.containsKey(i) ? baro[i]! + offset : gpsAltitudes[i],
  ];
}
