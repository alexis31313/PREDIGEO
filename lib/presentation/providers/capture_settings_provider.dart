// Parámetros configurables del proceso de captura de puntos GNSS.
//
// Se exponen como proveedor para que la interfaz nunca use valores
// "hardcodeados": hoy toman sus valores por defecto y en el futuro podrán
// editarse desde una pantalla de Ajustes sin tocar las vistas.

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Configuración de captura de puntos.
@immutable
class CaptureSettings {
  /// Número de muestras que se promedian por cada punto capturado.
  final int samplesPerPoint;

  /// Precisión horizontal máxima, en metros, para aceptar un punto capturado.
  /// Los puntos cuya precisión estimada supere este umbral se descartan.
  final double maxAccuracyM;

  /// Tiempo máximo de espera de la captura de un punto.
  final Duration timeout;

  const CaptureSettings({
    this.samplesPerPoint = 10,
    this.maxAccuracyM = 20.0,
    this.timeout = const Duration(seconds: 30),
  });

  CaptureSettings copyWith({
    int? samplesPerPoint,
    double? maxAccuracyM,
    Duration? timeout,
  }) {
    return CaptureSettings(
      samplesPerPoint: samplesPerPoint ?? this.samplesPerPoint,
      maxAccuracyM: maxAccuracyM ?? this.maxAccuracyM,
      timeout: timeout ?? this.timeout,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CaptureSettings &&
        other.samplesPerPoint == samplesPerPoint &&
        other.maxAccuracyM == maxAccuracyM &&
        other.timeout == timeout;
  }

  @override
  int get hashCode => Object.hash(samplesPerPoint, maxAccuracyM, timeout);
}

class CaptureSettingsNotifier extends Notifier<CaptureSettings> {
  @override
  CaptureSettings build() => const CaptureSettings();

  void setSamplesPerPoint(int samples) {
    if (samples < 1) return;
    state = state.copyWith(samplesPerPoint: samples);
  }

  void setMaxAccuracyM(double meters) {
    if (meters <= 0) return;
    state = state.copyWith(maxAccuracyM: meters);
  }

  void setTimeout(Duration timeout) {
    state = state.copyWith(timeout: timeout);
  }

  void reset() => state = const CaptureSettings();
}

final captureSettingsProvider =
    NotifierProvider<CaptureSettingsNotifier, CaptureSettings>(
  CaptureSettingsNotifier.new,
);
