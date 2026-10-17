import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/export/export_service.dart';
import '../../domain/entities/measurement.dart';
import '../../domain/entities/measurement_enums.dart';
import '../../core/utils/formatters.dart';
import '../../domain/usecases/geo/distance_calculator.dart';
import '../../domain/usecases/geo/slope_correction.dart';
import '../providers/measurement_repository_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/elevation_profile_chart.dart';
import '../widgets/measurement_map_view.dart';
import '../widgets/terrain_relief_view.dart';

class MeasurementDetailScreen extends ConsumerWidget {
  final int measurementId;

  const MeasurementDetailScreen({
    super.key,
    required this.measurementId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(measurementDetailProvider(measurementId));

    return Scaffold(
      appBar: detailAsync.when(
        data: (measurement) => AppBar(
          title: Text(measurement?.name ?? 'Detalle'),
          actions: [
            if (measurement != null) ...[
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showRenameDialog(context, ref, measurement),
                tooltip: 'Renombrar',
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () => _duplicateMeasurement(context, ref, measurement),
                tooltip: 'Duplicar',
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _confirmDelete(context, ref, measurement),
                tooltip: 'Eliminar',
              ),
            ],
          ],
        ),
        loading: () => AppBar(title: const Text('Cargando...')),
        error: (_, __) => AppBar(title: const Text('Error')),
      ),
      body: detailAsync.when(
        data: (measurement) {
          if (measurement == null) {
            return const Center(
              child: Text(
                'Medición no encontrada',
                style: TextStyle(fontSize: 18),
              ),
            );
          }
          return _DetailBody(measurement: measurement);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 12),
                Text(
                  'Error al cargar la medición',
                  style: TextStyle(color: Colors.red[700]),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(measurementDetailProvider(measurementId)),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    Measurement measurement,
  ) async {
    final controller = TextEditingController(text: measurement.name);
    final formKey = GlobalKey<FormState>();

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renombrar medición'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El nombre no puede estar vacío';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(controller.text.trim());
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (newName != null && newName != measurement.name) {
      final updated = measurement.copyWith(name: newName);
      await ref.read(measurementHistoryActionsProvider.notifier).edit(updated);
    }
  }

  Future<void> _showEditNotesDialog(
    BuildContext context,
    WidgetRef ref,
    Measurement measurement,
  ) async {
    final notesController = TextEditingController(text: measurement.notes ?? '');

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar notas y categoría'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notas',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<MeasurementCategory?>(
              value: measurement.category,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<MeasurementCategory?>(
                  value: null,
                  child: Text('Sin categoría'),
                ),
                ...MeasurementCategory.values.map(
                  (cat) => DropdownMenuItem<MeasurementCategory?>(
                    value: cat,
                    child: Text(cat.label),
                  ),
                ),
              ],
              onChanged: (_) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop({
                'notes': notesController.text,
              });
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != null) {
      final updated = measurement.copyWith(notes: result['notes']);
      await ref.read(measurementHistoryActionsProvider.notifier).edit(updated);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Measurement measurement,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar medición'),
        content: Text(
          '¿Está seguro de eliminar "${measurement.name}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(measurementHistoryActionsProvider.notifier).remove(measurement.id!);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Medición eliminada'),
            action: SnackBarAction(
              label: 'Deshacer',
              onPressed: () {
                ref.read(measurementHistoryActionsProvider.notifier).save(measurement);
              },
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _duplicateMeasurement(
    BuildContext context,
    WidgetRef ref,
    Measurement measurement,
  ) async {
    final duplicated = measurement.copyWith(
      id: null,
      name: '${measurement.name} (copia)',
      createdAt: DateTime.now(),
      points: measurement.points
          .map((p) => p.copyWith(id: null, measurementId: null))
          .toList(),
      evaluations: measurement.evaluations
          .map((e) => e.copyWith(id: null, measurementId: null))
          .toList(),
    );

    await ref.read(measurementHistoryActionsProvider.notifier).save(duplicated);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medición duplicada')),
      );
    }
  }
}

class _DetailBody extends ConsumerWidget {
  final Measurement measurement;

  const _DetailBody({required this.measurement});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    measurement.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.calendar_today,
                    label: 'Fecha',
                    value: Formatters.formatDate(measurement.createdAt),
                  ),
                  _InfoRow(
                    icon: Icons.category,
                    label: 'Tipo',
                    value: measurement.type.label,
                  ),
                  _InfoRow(
                    icon: Icons.wifi,
                    label: 'Modo',
                    value: measurement.mode.label,
                  ),
                  _InfoRow(
                    icon: Icons.terrain,
                    label: 'Categoría',
                    value: measurement.category?.label ?? 'Sin categoría',
                  ),
                  if (measurement.areaM2 != null)
                    _InfoRow(
                      icon: Icons.square_foot,
                      label: 'Área planimétrica',
                      value: ref.watch(
                        formattedAreaProvider(measurement.areaM2!),
                      ),
                    ),
                  if (measurement.areaM2 != null &&
                      measurement.points.length >= 3)
                    _InfoRow(
                      icon: Icons.landscape,
                      label: 'Área sobre el terreno',
                      value: ref.watch(
                        formattedAreaProvider(
                          SlopeCorrection.slopedArea(
                            measurement.areaM2!,
                            measurement.points,
                          ),
                        ),
                      ),
                    ),
                  if (measurement.perimeterM != null)
                    _InfoRow(
                      icon: Icons.pentagon,
                      label: 'Perímetro',
                      value: Formatters.formatDistance(measurement.perimeterM!),
                    ),
                  if (measurement.perimeterM != null &&
                      measurement.points.length >= 2)
                    _InfoRow(
                      icon: Icons.trending_up,
                      label: 'Perímetro sobre el terreno',
                      value: Formatters.formatDistance(
                        DistanceCalculator.perimeter3D(measurement.points),
                      ),
                    ),
                  if (measurement.distanceM != null)
                    _InfoRow(
                      icon: Icons.straighten,
                      label: 'Distancia horizontal',
                      value: Formatters.formatDistance(measurement.distanceM!),
                    ),
                  if (measurement.distanceM != null &&
                      measurement.points.length >= 2)
                    _InfoRow(
                      icon: Icons.route,
                      label: 'Distancia sobre el terreno',
                      value: Formatters.formatDistance(
                        DistanceCalculator.pathLength3D(measurement.points),
                      ),
                    ),
                  if ((measurement.areaM2 != null ||
                          measurement.distanceM != null) &&
                      measurement.points.length >= 2)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Planimétrico: proyección horizontal (comparable con '
                        'IGAC). Sobre el terreno: incluye el relieve según '
                        'la altitud GPS (aproximada).',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  if (measurement.avgAccuracyM != null)
                    _InfoRow(
                      icon: Icons.gps_fixed,
                      label: 'Precisión media',
                      value:
                          '${measurement.avgAccuracyM!.toStringAsFixed(1)} m (${Formatters.formatAccuracy(measurement.avgAccuracyM!)})',
                    ),
                  if (measurement.notes != null && measurement.notes!.isNotEmpty)
                    _InfoRow(
                      icon: Icons.notes,
                      label: 'Notas',
                      value: measurement.notes!,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (measurement.points.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mapa',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    MeasurementMapView(
                      points: measurement.points,
                      type: measurement.type,
                      online: measurement.mode ==
                          MeasurementMode.online,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Perfil del terreno',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TerrainReliefView(points: measurement.points),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gráfico de elevación',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevationProfileChart(points: measurement.points),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Puntos (${measurement.pointCount})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _exportPoints(context),
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('Exportar'),
                      ),
                    ],
                  ),
                  const Divider(),
                  ...measurement.points.asMap().entries.map((entry) {
                    final index = entry.key;
                    final point = entry.value;
                    return _PointTile(
                      index: index,
                      point: point,
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPoints(BuildContext context) async {
    try {
      final points = measurement.points;
      if (points.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No hay puntos para exportar')),
          );
        }
        return;
      }
      final measurementForExport = measurement;
      await ExportService().exportPointsToCSV(measurementForExport, points);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Puntos exportados')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar: $e')),
        );
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _PointTile extends StatelessWidget {
  final int index;
  final dynamic point;

  const _PointTile({
    required this.index,
    required this.point,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 16,
        child: Text(
          '${index + 1}',
          style: const TextStyle(fontSize: 12),
        ),
      ),
      title: Text(
        'Punto ${point.seq}',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        'Lat: ${Formatters.formatCoordinate(point.latitude, 6)}\n'
        'Lon: ${Formatters.formatCoordinate(point.longitude, 6)}\n'
        'Alt: ${point.altitude.toStringAsFixed(2)} m | Prec: ${point.accuracy.toStringAsFixed(1)} m',
        style: const TextStyle(fontSize: 12),
      ),
      isThreeLine: true,
    );
  }
}
