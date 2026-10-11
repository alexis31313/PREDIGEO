// Proveedores de Riverpod para el estado de conectividad.
//
// La aplicación alterna automáticamente entre el modo conectado (mapa de
// Google Maps) y el modo sin conexión (vista de relieve local) según el estado
// real de la red, obtenido de `ConnectivityDataSource` (connectivity_plus).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/remote/connectivity_datasource.dart';

enum ConnectionStatus { connected, disconnected, unknown }

/// Fuente de datos de conectividad. Se puede sobrescribir en pruebas.
final connectivityDataSourceProvider = Provider<ConnectivityDataSource>((ref) {
  return ConnectivityDataSource();
});

/// Verificación inicial (una sola vez) del estado de conexión.
final isConnectedProvider = FutureProvider<bool>((ref) {
  return ref.watch(connectivityDataSourceProvider).isConnected();
});

/// Stream de cambios de red, normalizado a [ConnectionStatus].
final connectionStreamProvider = StreamProvider<ConnectionStatus>((ref) {
  return ref.watch(connectivityDataSourceProvider).connectionStream().map(
        (connected) => connected
            ? ConnectionStatus.connected
            : ConnectionStatus.disconnected,
      );
});

/// Estado de conexión efectivo: prioriza el último valor del stream y, mientras
/// este aún no ha emitido, usa la verificación inicial.
final connectionStatusProvider = Provider<ConnectionStatus>((ref) {
  final changes = ref.watch(connectionStreamProvider).asData?.value;
  if (changes != null) return changes;

  final initial = ref.watch(isConnectedProvider);
  return initial.when(
    data: (connected) =>
        connected ? ConnectionStatus.connected : ConnectionStatus.disconnected,
    error: (_, __) => ConnectionStatus.unknown,
    loading: () => ConnectionStatus.unknown,
  );
});

/// `true` cuando hay conexión a internet disponible.
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectionStatusProvider) == ConnectionStatus.connected;
});
