// Pantalla de justificación de permisos de PrediGeo.
// Explica por qué se necesita la ubicación precisa y que los datos no salen
// del teléfono en modo sin conexión. Reutiliza LocationService.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../providers/gps_state_notifier.dart';
import '../providers/settings_provider.dart';

/// Tercera pantalla del flujo de primer uso.
class PermissionRationaleScreen extends ConsumerStatefulWidget {
  const PermissionRationaleScreen({super.key});

  @override
  ConsumerState<PermissionRationaleScreen> createState() =>
      _PermissionRationaleScreenState();
}

class _PermissionRationaleScreenState
    extends ConsumerState<PermissionRationaleScreen> {
  bool _loading = false;
  bool _permanentlyDenied = false;
  String? _message;

  Future<void> _requestPermission() async {
    setState(() {
      _loading = true;
      _message = null;
      _permanentlyDenied = false;
    });
    try {
      // Reutiliza la lógica centralizada de LocationService.
      final service = ref.read(locationServiceProvider);
      final result = await service.requestPermission();
      if (!mounted) return;
      if (result == 'granted') {
        await ref.read(settingsProvider.notifier).completePermissionStep();
        if (mounted) context.go('/');
      } else if (result == 'deniedForever') {
        setState(() {
          _permanentlyDenied = true;
          _message = 'El permiso quedó denegado de forma permanente. '
              'Abre los ajustes del sistema para habilitarlo.';
        });
      } else {
        setState(() {
          _message = 'Se necesita el permiso de ubicación para medir. '
              'Inténtalo de nuevo.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _message = 'Error al solicitar permiso: $e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openSettings() async {
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permiso de ubicación'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              '¿Por qué necesitamos tu ubicación precisa?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'PrediGeo mide áreas y trayectos con el GPS de tu teléfono. '
              'Sin la ubicación precisa no puede capturar puntos ni calcular '
              'el área.\n\n'
              'Tus datos no salen del teléfono en modo sin conexión: todo se '
              'guarda localmente en SQLite.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 24),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _loading ? null : _requestPermission,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: const Text('Permitir ubicación precisa'),
              ),
            ),
            if (_permanentlyDenied) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openSettings,
                  icon: const Icon(Icons.settings),
                  label: const Text('Abrir ajustes del sistema'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
