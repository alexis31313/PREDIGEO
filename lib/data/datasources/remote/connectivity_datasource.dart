/// Fuente de datos de conectividad para PrediGeo.
/// Gestiona la detección del estado de conexión a internet del dispositivo
/// usando connectivity_plus. Permite determinar si la aplicación opera
/// en modo online u offline.
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityDataSource {
  final Connectivity _connectivity;

  ConnectivityDataSource({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  Future<bool> isConnected() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return _isConnectedFromResults(results);
    } catch (e) {
      throw Exception('Error al verificar la conexión: $e');
    }
  }

  Stream<bool> connectionStream() {
    try {
      return _connectivity.onConnectivityChanged
          .map((results) => _isConnectedFromResults(results))
          .handleError((error) {
        throw Exception('Error en el stream de conectividad: $error');
      });
    } catch (e) {
      throw Exception('Error al iniciar el stream de conectividad: $e');
    }
  }

  bool _isConnectedFromResults(List<ConnectivityResult> results) {
    return results.any(
      (result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet,
    );
  }
}
