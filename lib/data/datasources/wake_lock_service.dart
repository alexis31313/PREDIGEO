import 'package:wakelock_plus/wakelock_plus.dart';

/// Servicio que evita que la pantalla del dispositivo se apague mientras se
/// realiza una captura de puntos GNSS.
///
/// Se aísla detrás de esta clase para poder sustituirlo en las pruebas sin
/// invocar los canales de plataforma de `wakelock_plus`.
class WakeLockService {
  const WakeLockService();

  /// Mantiene la pantalla encendida.
  Future<void> enable() => WakelockPlus.enable();

  /// Permite que la pantalla vuelva a apagarse según la configuración del
  /// dispositivo.
  Future<void> disable() => WakelockPlus.disable();
}
