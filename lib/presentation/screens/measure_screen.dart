// Pantalla de Nueva Medición en modo sin conexión.
//
// Permite capturar puntos GNSS (promediando varias muestras por punto),
// visualizar el resultado calculado (área o distancia, más el perfil de
// altitud) y guardar la medición localmente en SQLite. Toda la captura y el
// cálculo funcionan sin conexión a internet.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/location_status.dart';
import '../../domain/entities/measurement.dart';
import '../../domain/entities/measurement_enums.dart';
import '../../domain/usecases/geo/area_units.dart';
import '../../domain/usecases/signal_processing/point_capture_service.dart';
import '../providers/capture_service_provider.dart';
import '../providers/capture_settings_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/gps_state_notifier.dart';
import '../providers/measurement_repository_provider.dart';
import '../providers/measurement_session_provider.dart';
import '../widgets/elevation_profile_chart.dart';
import '../widgets/measurement_map_section.dart';
import '../widgets/offline_banner.dart';
import '../widgets/signal_indicator.dart';

class MeasureScreen extends ConsumerStatefulWidget {
  const MeasureScreen({super.key});

  @override
  ConsumerState<MeasureScreen> createState() => _MeasureScreenState();
}

class _MeasureScreenState extends ConsumerState<MeasureScreen> {
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gpsStateNotifierProvider.notifier).start();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _capturePoint() async {
    final settings = ref.read(captureSettingsProvider);
    final notifier = ref.read(measurementSessionProvider.notifier);
    final wakeLock = ref.read(wakeLockServiceProvider);

    notifier.startCapture();
    await wakeLock.enable();
    try {
      final captured = await ref.read(pointCaptureServiceProvider).capturePoint(
            samples: settings.samplesPerPoint,
            timeout: settings.timeout,
            onProgress: notifier.updateCaptureProgress,
          );

      if (captured.estimatedAccuracy > settings.maxAccuracyM) {
        notifier.failCapture(
          'Punto descartado: precisión de '
          '${captured.estimatedAccuracy.toStringAsFixed(1)} m, superior al '
          'umbral de ${settings.maxAccuracyM.toStringAsFixed(0)} m. '
          'Acérquese a un sitio despejado e intente de nuevo.',
        );
      } else {
        notifier.addCapturedPoint(captured);
      }
    } on InsufficientSamplesException catch (e) {
      notifier.failCapture(e.message);
    } catch (e) {
      notifier.failCapture('No se pudo capturar el punto: $e');
    } finally {
      await wakeLock.disable();
    }
  }

  Future<void> _save() async {
    final session = ref.read(measurementSessionProvider);
    if (!session.canSave) return;

    final measurement = Measurement(
      name: session.name.trim(),
      type: session.type,
      areaM2: session.areaM2,
      perimeterM: session.perimeterM,
      distanceM: session.distanceM,
      mode: MeasurementMode.offline,
      category: session.category,
      notes: session.notes.trim().isEmpty ? null : session.notes.trim(),
      createdAt: DateTime.now(),
      points: session.points,
    );

    try {
      await ref
          .read(measurementHistoryActionsProvider.notifier)
          .save(measurement);

      if (!mounted) return;
      ref.read(measurementSessionProvider.notifier).reset();
      _nameController.clear();
      _notesController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medición guardada localmente.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar la medición: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(measurementSessionProvider);
    final settings = ref.watch(captureSettingsProvider);
    final gpsStatus = ref.watch(gpsStateNotifierProvider);
    final liveReading = ref.watch(gpsReadingStreamProvider).asData?.value;

    final gpsDisabled =
        gpsStatus is PermissionDenied || gpsStatus is ServiceDisabled;
    final gpsMessage = switch (gpsStatus) {
      PermissionDenied(:final message) => message,
      ServiceDisabled(:final message) => message,
      _ => null,
    };
    final isOnline = ref.watch(isOnlineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Medición'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          if (!isOnline) const OfflineBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildTypeSelector(session),
                const SizedBox(height: 16),
                _buildSignalCard(liveReading, gpsMessage),
                const SizedBox(height: 16),
                _buildCaptureParams(settings),
                const SizedBox(height: 16),
                _buildResultsCard(session),
                if (session.pointCount >= 2) ...[
                  const SizedBox(height: 16),
                  _buildReliefSection(session),
                ],
                const SizedBox(height: 16),
                _buildPointsCard(session),
                if (session.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _buildErrorMessage(session.errorMessage!),
                ],
                const SizedBox(height: 16),
                _buildFormFields(session),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(session, gpsDisabled),
    );
  }

  Widget _buildTypeSelector(MeasurementSessionState session) {
    return SegmentedButton<MeasurementType>(
      segments: const [
        ButtonSegment(
          value: MeasurementType.area,
          label: Text('Área'),
          icon: Icon(Icons.crop_square),
        ),
        ButtonSegment(
          value: MeasurementType.path,
          label: Text('Trayecto'),
          icon: Icon(Icons.route),
        ),
      ],
      selected: {session.type},
      onSelectionChanged: session.isCapturing
          ? null
          : (selection) {
              ref
                  .read(measurementSessionProvider.notifier)
                  .setType(selection.first);
            },
    );
  }

  Widget _buildSignalCard(liveReading, String? gpsMessage) {
    final accuracy = liveReading?.horizontalAccuracy;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Señal GPS',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SignalIndicator(accuracy: accuracy),
              ],
            ),
            if (gpsMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                gpsMessage,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ] else if (liveReading != null) ...[
              const SizedBox(height: 8),
              Text(
                'Lat ${liveReading.latitude.toStringAsFixed(6)} · '
                'Lon ${liveReading.longitude.toStringAsFixed(6)} · '
                'Alt ${liveReading.altitude.toStringAsFixed(1)} m',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureParams(CaptureSettings settings) {
    return Text(
      'Parámetros: ${settings.samplesPerPoint} muestras por punto · '
      'precisión máxima ${settings.maxAccuracyM.toStringAsFixed(0)} m',
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildResultsCard(MeasurementSessionState session) {
    final rows = <Widget>[
      _metricRow('Puntos capturados', '${session.pointCount}'),
    ];

    if (session.type == MeasurementType.area) {
      if (session.areaM2 != null) {
        rows.add(_metricRow('Área', AreaUnits.formatArea(session.areaM2!)));
      }
      if (session.perimeterM != null) {
        rows.add(_metricRow('Perímetro', _formatMeters(session.perimeterM!)));
      }
    } else if (session.distanceM != null) {
      rows.add(_metricRow('Distancia', _formatMeters(session.distanceM!)));
    }

    if (session.pointCount > 0) {
      rows.add(
        _metricRow('Precisión media', _formatMeters(session.avgAccuracyM)),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resultado',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...rows,
            if (!session.hasEnoughPoints) ...[
              const SizedBox(height: 8),
              Text(
                session.type == MeasurementType.area
                    ? 'Capture al menos 3 puntos para calcular el área.'
                    : 'Capture al menos 2 puntos para calcular la distancia.',
                style: const TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReliefSection(MeasurementSessionState session) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Perfil de altitud',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: ElevationProfileChart(points: session.points),
            ),
            const SizedBox(height: 16),
            const Text(
              'Mapa / relieve',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: MeasurementMapSection(
                points: session.points,
                closePolygon: session.type == MeasurementType.area,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsCard(MeasurementSessionState session) {
    final points = session.points;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Puntos',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                if (points.isNotEmpty)
                  TextButton.icon(
                    onPressed: session.isCapturing
                        ? null
                        : () => ref
                            .read(measurementSessionProvider.notifier)
                            .removeLastPoint(),
                    icon: const Icon(Icons.undo, size: 18),
                    label: const Text('Deshacer'),
                  ),
              ],
            ),
            if (points.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Todavía no hay puntos capturados.'),
              )
            else
              for (var i = 0; i < points.length; i++)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 14,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  title: Text(
                    'Lat ${points[i].latitude.toStringAsFixed(6)}, '
                    'Lon ${points[i].longitude.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  subtitle: Text(
                    'Alt ${points[i].altitude.toStringAsFixed(1)} m · '
                    'Precisión ${points[i].accuracy.toStringAsFixed(1)} m',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colors.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields(MeasurementSessionState session) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _nameController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Nombre de la medición',
            hintText: 'Ej. Lote norte',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) =>
              ref.read(measurementSessionProvider.notifier).setName(value),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<MeasurementCategory>(
          initialValue: session.category,
          decoration: const InputDecoration(
            labelText: 'Categoría de terreno',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<MeasurementCategory>(
              value: null,
              child: Text('Sin clasificar'),
            ),
            for (final category in MeasurementCategory.values)
              DropdownMenuItem<MeasurementCategory>(
                value: category,
                child: Text(category.label),
              ),
          ],
          onChanged: (value) =>
              ref.read(measurementSessionProvider.notifier).setCategory(value),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Observaciones (opcional)',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) =>
              ref.read(measurementSessionProvider.notifier).setNotes(value),
        ),
      ],
    );
  }

  Widget _buildBottomBar(
    MeasurementSessionState session,
    bool gpsDisabled,
  ) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    (session.isCapturing || gpsDisabled) ? null : _capturePoint,
                icon: session.isCapturing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_location_alt),
                label: Text(
                  session.isCapturing
                      ? 'Capturando... '
                          '${(session.captureProgress * 100).round()}%'
                      : 'Capturar punto',
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: session.canSave ? _save : null,
                icon: const Icon(Icons.save),
                label: const Text('Guardar medición'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _formatMeters(double meters) {
    final fmt = NumberFormat('#,##0.00', 'es_CO');
    return '${fmt.format(meters)} m';
  }
}
