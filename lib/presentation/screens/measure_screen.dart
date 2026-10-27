// Pantalla de Nueva Medición en modo sin conexión.
//
// Permite capturar puntos GNSS (promediando varias muestras por punto),
// visualizar el resultado calculado (área o distancia, más el perfil de
// altitud) y guardar la medición localmente en SQLite. Toda la captura y el
// cálculo funcionan sin conexión a internet.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
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
        await HapticFeedback.mediumImpact();
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
                _buildResultsCard(session),
                const SizedBox(height: 8),
                _buildCaptureParams(settings),
                if (session.pointCount >= 1) ...[
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
    final String primaryLabel;
    final String primaryValue;
    final secondaryMetrics = <Widget>[];
    if (session.type == MeasurementType.area) {
      primaryLabel = 'Área';
      primaryValue =
          session.areaM2 == null ? '—' : AreaUnits.formatArea(session.areaM2!);
      if (session.perimeterM != null) {
        secondaryMetrics.add(
          _metricRow('Perímetro', _formatMeters(session.perimeterM!)),
        );
      }
    } else {
      primaryLabel = 'Distancia';
      primaryValue =
          session.distanceM == null ? '—' : _formatMeters(session.distanceM!);
    }
    if (session.pointCount > 0) {
      secondaryMetrics.add(
        _metricRow('Precisión media', _formatMeters(session.avgAccuracyM)),
      );
    }
    secondaryMetrics.insert(
      0,
      _metricRow('Puntos capturados', '${session.pointCount}'),
    );
    final status = Theme.of(context).extension<AppStatusColors>();
    final warningColor =
        status?.warning ?? Theme.of(context).colorScheme.tertiary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resultado', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    primaryLabel,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    primaryValue,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: secondaryMetrics,
            ),
            if (!session.hasEnoughPoints) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: warningColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: warningColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        session.type == MeasurementType.area
                            ? 'Capture al menos 3 puntos para calcular el área.'
                            : 'Capture al menos 2 puntos para calcular la distancia.',
                        style: TextStyle(color: warningColor, fontSize: 12),
                      ),
                    ),
                  ],
                ),
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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: MeasurementMapSection(
                  key: ValueKey(session.type),
                  points: session.points,
                  closePolygon: session.type == MeasurementType.area,
                ),
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
                _PointTimelineItem(
                  index: i,
                  isLast: i == points.length - 1,
                  latitude: points[i].latitude,
                  longitude: points[i].longitude,
                  altitude: points[i].altitude,
                  accuracy: points[i].accuracy,
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
          ),
          onChanged: (value) =>
              ref.read(measurementSessionProvider.notifier).setName(value),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<MeasurementCategory>(
          initialValue: session.category,
          decoration: const InputDecoration(
            labelText: 'Categoría de terreno',
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
          ),
          onChanged: (value) =>
              ref.read(measurementSessionProvider.notifier).setNotes(value),
        ),
      ],
    );
  }

  Widget _buildBottomBar(MeasurementSessionState session, bool gpsDisabled) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (session.isCapturing) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: session.captureProgress.clamp(0.0, 1.0),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: (session.isCapturing || gpsDisabled)
                      ? null
                      : _capturePoint,
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: session.isCapturing
                        ? SizedBox(
                            key: const ValueKey('capture-progress'),
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.add_location_alt,
                            key: ValueKey('capture-ready'),
                          ),
                  ),
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
      ),
    );
  }

  Widget _metricRow(String label, String value) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 128),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 3),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium,
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

class _PointTimelineItem extends StatelessWidget {
  final int index;
  final bool isLast;
  final double latitude;
  final double longitude;
  final double altitude;
  final double accuracy;

  const _PointTimelineItem({
    required this.index,
    required this.isLast,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracy,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 36,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (!isLast)
                  Positioned(
                    top: 28,
                    bottom: 0,
                    child: Container(width: 2, color: colors.outlineVariant),
                  ),
                Align(
                  alignment: Alignment.topCenter,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: colors.primaryContainer,
                    foregroundColor: colors.onPrimaryContainer,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lat ${latitude.toStringAsFixed(6)}, '
                    'Lon ${longitude.toStringAsFixed(6)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Alt ${altitude.toStringAsFixed(1)} m · '
                    'Precisión ${accuracy.toStringAsFixed(1)} m',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
