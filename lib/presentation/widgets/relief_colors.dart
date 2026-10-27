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
