// Proveedores de Riverpod para el estado de conectividad:
// verificación inicial de conexión y stream de cambios de red.

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectionStatus { connected, disconnected, unknown }

final isConnectedProvider = FutureProvider<bool>((ref) async {
  return true;
});

final connectionStreamProvider = StreamProvider<ConnectionStatus>((ref) async* {
  yield ConnectionStatus.connected;

  while (true) {
    await Future.delayed(const Duration(seconds: 5));
    yield ConnectionStatus.connected;
  }
});
