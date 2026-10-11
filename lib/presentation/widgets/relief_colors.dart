import 'package:flutter/material.dart';

/// Paleta de degradado hipsométrico compartida por las visualizaciones de
/// relieve de PrediGeo.
///
/// El parámetro [t] es la posición normalizada de una altitud dentro del rango
/// del recorrido (0 = la más baja, 1 = la más alta). El degradado va de azul
/// (zonas bajas) a verde (intermedias) y a marrón (zonas altas), siguiendo la
/// convención cartográfica habitual.
const Color reliefLowColor = Color(0xFF1E88E5);
const Color reliefMidColor = Color(0xFF43A047);
const Color reliefHighColor = Color(0xFF795548);

Color altitudeColor(double t) {
  final clamped = t.clamp(0.0, 1.0);
  if (clamped <= 0.5) {
    return Color.lerp(reliefLowColor, reliefMidColor, clamped * 2)!;
  }
  return Color.lerp(reliefMidColor, reliefHighColor, (clamped - 0.5) * 2)!;
}
