// Pantalla de ajustes de PrediGeo.
// Permite configurar el modo de operación, muestras por punto, umbral de
// precisión GPS, unidad de área y tema. Incluye sección "Acerca de".
// Toda la persistencia es offline mediante shared_preferences.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../domain/entities/measurement_enums.dart';
import '../providers/settings_provider.dart';

/// Pantalla de configuración de la aplicación.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle(title: 'Medición'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.wifi),
                  title: const Text('Modo de operación'),
                  subtitle: Text(settings.operationMode.label),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SegmentedButton<MeasurementMode>(
                    segments: const [
                      ButtonSegment(
                        value: MeasurementMode.offline,
                        label: Text('Sin conexión'),
                        icon: Icon(Icons.cloud_off),
                      ),
                      ButtonSegment(
                        value: MeasurementMode.online,
                        label: Text('En línea'),
                        icon: Icon(Icons.cloud),
                      ),
                    ],
                    selected: {settings.operationMode},
                    onSelectionChanged: (selected) {
                      notifier.setOperationMode(selected.first);
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.gps_fixed),
                  title: const Text('Muestras por punto'),
                  subtitle: Text(
                    '${settings.samplesPerPoint} muestras (5 a 30)',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: settings.samplesPerPoint.toDouble(),
                          min: 5,
                          max: 30,
                          divisions: 25,
                          label: '${settings.samplesPerPoint}',
                          onChanged: (value) {
                            notifier.setSamplesPerPoint(value.round());
                          },
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        child: Text(
                          '${settings.samplesPerPoint}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.radar),
                  title: const Text('Umbral de precisión GPS'),
                  subtitle: Text(
                    '${settings.gpsAccuracyThreshold.toStringAsFixed(1)} m '
                    '(se descartan lecturas peores)',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: settings.gpsAccuracyThreshold,
                          min: 3,
                          max: 50,
                          divisions: 47,
                          label:
                              '${settings.gpsAccuracyThreshold.toStringAsFixed(1)} m',
                          onChanged: (value) {
                            notifier.setGpsAccuracyThreshold(value);
                          },
                        ),
                      ),
                      SizedBox(
                        width: 64,
                        child: Text(
                          '${settings.gpsAccuracyThreshold.toStringAsFixed(1)} m',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle(title: 'Visualización'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.square_foot),
                  title: const Text('Unidad de área preferida'),
                  subtitle: Text(settings.areaUnit.label),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SegmentedButton<AreaUnitPref>(
                    segments: const [
                      ButtonSegment(
                        value: AreaUnitPref.squareMeters,
                        label: Text('m²'),
                      ),
                      ButtonSegment(
                        value: AreaUnitPref.hectares,
                        label: Text('ha'),
                      ),
                      ButtonSegment(
                        value: AreaUnitPref.fanegadas,
                        label: Text('Fanegada'),
                      ),
                    ],
                    selected: {settings.areaUnit},
                    onSelectionChanged: (selected) {
                      notifier.setAreaUnit(selected.first);
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.dark_mode),
                  title: const Text('Tema'),
                  subtitle: Text(_themeLabel(settings.themeMode)),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Claro'),
                        icon: Icon(Icons.light_mode),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Oscuro'),
                        icon: Icon(Icons.dark_mode),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('Sistema'),
                        icon: Icon(Icons.settings),
                      ),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (selected) {
                      notifier.setThemeMode(selected.first);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle(title: 'Acerca de'),
          const _AboutCard(),
        ],
      ),
    );
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Oscuro';
      case ThemeMode.system:
        return 'Sistema';
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

/// Tarjeta "Acerca de" con versión, equipo y asesor.
class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.terrain,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PrediGeo',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Medición de áreas y trayectos con GPS/GNSS',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.hasData
                    ? 'v${snapshot.data!.version} (${snapshot.data!.buildNumber})'
                    : 'v1.0.0';
                return Text(
                  'Versión: $version',
                  style: const TextStyle(fontSize: 14),
                );
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'Equipo: Steve Alexander Calvache Martinez y '
              'Luis Alejandro Paz Acero.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Text(
              'Asesor: Jhon Alexander Gómez.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tecnología en Desarrollo de Software — Mocoa, Putumayo.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
