import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../domain/entities/location_status.dart';
import '../providers/gps_state_notifier.dart';
import '../widgets/signal_indicator.dart';

class GpsDebugScreen extends ConsumerWidget {
  const GpsDebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationStatus = ref.watch(gpsStateNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS Debug'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Center(
              child: SignalIndicator(
                accuracy: _extractAccuracy(locationStatus),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusCard(locationStatus),
          Expanded(
            child: _buildDataList(locationStatus),
          ),
          _buildControlButtons(ref),
        ],
      ),
    );
  }

  double? _extractAccuracy(LocationStatus status) {
    return switch (status) {
      Ready(reading: final reading?) => reading.horizontalAccuracy,
      _ => null,
    };
  }

  Widget _buildStatusCard(LocationStatus status) {
    return status.when(
      permissionDenied: (s) => _StatusCard(
        color: Colors.red,
        icon: Icons.location_disabled,
        title: 'Permiso denegado',
        message: s.message ??
            'Se requiere permiso de ubicación para acceder al GPS.',
      ),
      serviceDisabled: (s) => _StatusCard(
        color: Colors.orange,
        icon: Icons.location_off,
        title: 'Servicio deshabilitado',
        message: s.message ??
            'El servicio de ubicación está deshabilitado en el dispositivo.',
      ),
      acquiring: (s) => _StatusCard(
        color: Colors.blue,
        icon: Icons.my_location,
        title: 'Adquiriendo ubicación',
        message: s.message ?? 'Esperando señal del GPS...',
        isLoading: true,
      ),
      ready: (s) => _StatusCard(
        color: Colors.green,
        icon: Icons.location_on,
        title: 'Señal disponible',
        message: 'Datos GPS recibidos correctamente.',
      ),
    );
  }

  Widget _buildDataList(LocationStatus status) {
    final reading = switch (status) {
      Ready(reading: final r?) => r,
      _ => null,
    };

    if (reading == null) {
      return const Center(
        child: Text(
          'Sin datos disponibles',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _DataTile(
          icon: Icons.public,
          label: 'Latitud',
          value: Formatters.formatCoordinate(reading.latitude, 6),
        ),
        _DataTile(
          icon: Icons.public,
          label: 'Longitud',
          value: Formatters.formatCoordinate(reading.longitude, 6),
        ),
        _DataTile(
          icon: Icons.terrain,
          label: 'Altitud',
          value: '${reading.altitude.toStringAsFixed(2)} m',
        ),
        _DataTile(
          icon: Icons.gps_fixed,
          label: 'Precisión horizontal',
          value: '${reading.horizontalAccuracy.toStringAsFixed(1)} m',
        ),
        _DataTile(
          icon: Icons.height,
          label: 'Precisión altitud',
          value: '${reading.altitudeAccuracy.toStringAsFixed(1)} m',
        ),
        _DataTile(
          icon: Icons.speed,
          label: 'Velocidad',
          value: '${reading.speed.toStringAsFixed(1)} m/s',
        ),
        _DataTile(
          icon: Icons.access_time,
          label: 'Marca de tiempo',
          value: Formatters.formatDate(reading.timestamp),
        ),
      ],
    );
  }

  Widget _buildControlButtons(WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () =>
                  ref.read(gpsStateNotifierProvider.notifier).start(),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Iniciar'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () =>
                  ref.read(gpsStateNotifierProvider.notifier).stop(),
              icon: const Icon(Icons.stop),
              label: const Text('Detener'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String message;
  final bool isLoading;

  const _StatusCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.message,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          if (isLoading)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: color,
              ),
            )
          else
            Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DataTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DataTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label),
      trailing: Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}
