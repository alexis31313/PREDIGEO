import 'package:flutter/material.dart';

/// Paleta de degradado hipsométrico compartida por las visualizaciones de
/// relieve de PrediGeo.
///
/// El parámetro [t] es la posición normalizada de una altitud dentro del rango
/// del recorrido (0 = la más baja, 1 = la más alta). El degradado va de azul
/// (zonas bajas) a verde (intermedias) y a marrón (zonas altas), siguiendo la
/// convención cartográfica habitual.
Color altitudeColor(
  double t, {
  required Color low,
  required Color middle,
  required Color high,
}) {
  final clamped = t.clamp(0.0, 1.0);
  if (clamped <= 0.5) {
    return Color.lerp(low, middle, clamped * 2)!;
  }
  return Color.lerp(middle, high, (clamped - 0.5) * 2)!;
}

/// Paradas de la paleta hipsométrica fija usada por la vista 3D: azul
/// (zonas bajas) → verde → ocre → marrón (zonas altas). No depende del tema
/// para que los colores signifiquen siempre lo mismo.
const List<Color> hypsometricStops = <Color>[
  Color(0xFF3A78C9),
  Color(0xFF3FA66B),
  Color(0xFF9CC45A),
  Color(0xFFD9B95B),
  Color(0xFF8B5A2B),
];

/// Color hipsométrico para la posición normalizada [t] (0 = más bajo,
/// 1 = más alto) dentro del rango de altitudes.
Color hypsometricColor(double t) {
  final clamped = t.isFinite ? t.clamp(0.0, 1.0) : 0.5;
  final scaled = clamped * (hypsometricStops.length - 1);
  final i = scaled.floor().clamp(0, hypsometricStops.length - 2);
  return Color.lerp(hypsometricStops[i], hypsometricStops[i + 1], scaled - i)!;
}
