import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../../domain/entities/field_evaluation.dart';
import '../../domain/entities/measurement.dart';
import '../../domain/entities/measurement_enums.dart';
import '../providers/measurement_repository_provider.dart';
import '../widgets/terrain_relief_toggle_view.dart';

/// Detalle de una medición guardada: cabecera, resultados, puntos y evaluaciones.
///
/// Se navega desde el [HistoryScreen] y permite revisar la información completa
/// de la medición, así como eliminarla de forma permanente.
class MeasurementDetailScreen extends ConsumerStatefulWidget {
  final int id;

  const MeasurementDetailScreen({super.key, required this.id});

  @override
  ConsumerState<MeasurementDetailScreen> createState() =>
      _MeasurementDetailScreenState();
}

class _MeasurementDetailScreenState extends ConsumerState<MeasurementDetailScreen> {
  Future<void> _remove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar medición'),
        content: const Text('¿Seguro que deseas eliminar esta medición?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(measurementHistoryActionsProvider.notifier)
        .remove(widget.id);
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final measurement = ref.watch(measurementDetailProvider(widget.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de medición'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _remove,
        icon: const Icon(Icons.delete_outline),
        label: const Text('Eliminar'),
      ),
      body: measurement.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _DetailErrorView(message: error.toString()),
        data: (measurement) {
          final result = measurement;
          if (result == null) return const _DetailEmptyView();
          return _DetailContent(measurement: result);
        },
      ),
    );
  }
}

class _DetailContent extends ConsumerWidget {
  final Measurement measurement;

  const _DetailContent({required this.measurement});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final evaluations = ref.watch(fieldEvaluationsProvider(measurement.id!));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MeasurementHeader(measurement: measurement),
          const SizedBox(height: 12),
          _MeasurementStats(measurement: measurement),
          const SizedBox(height: 12),
          if (measurement.points.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Relieve del terreno',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 260,
                      child: TerrainReliefToggleView(
                        points: measurement.points,
                        closePolygon: measurement.isArea,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          evaluations.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _DetailErrorView(message: error.toString()),
            data: (evaluations) => _EvaluationsList(evaluations: evaluations),
          ),
        ],
      ),
    );
  }
}

class _MeasurementHeader extends StatelessWidget {
  final Measurement measurement;

  const _MeasurementHeader({required this.measurement});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              measurement.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Badge(
                  icon: measurement.isArea ? Icons.crop_square : Icons.route,
                  label: measurement.type.label,
                ),
                _Badge(
                  icon: measurement.isOffline ? Icons.wifi_off : Icons.cloud_done,
                  label: measurement.mode.label,
                ),
                if (measurement.category != null)
                  _Badge(
                    icon: Icons.terrain,
                    label: measurement.category!.label,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Capturada el ${Formatters.formatDate(measurement.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Badge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.onPrimaryContainer),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colors.onPrimaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MeasurementStats extends StatelessWidget {
  final Measurement measurement;

  const _MeasurementStats({required this.measurement});

  @override
  Widget build(BuildContext context) {
    final areaLabel = measurement.isArea
        ? 'Área'
        : measurement.isPath
            ? 'Distancia'
            : 'Resultado';
    final areaValue = measurement.isArea
        ? Formatters.formatArea(measurement.areaM2 ?? 0)
        : Formatters.formatDistance(measurement.distanceM ?? 0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resultados',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _StatRow(
              label: areaLabel,
              value: areaValue,
              context: context,
            ),
            if (measurement.perimeterM != null && measurement.isArea)
              _StatRow(
                label: 'Perímetro',
                value:
                    '${measurement.perimeterM!.toStringAsFixed(2)} m',
                context: context,
              ),
            _StatRow(
              label: 'Precisión media',
              value: Formatters.formatAccuracy(measurement.avgAccuracyM ?? 0),
              context: context,
            ),
            _StatRow(
              label: 'Puntos',
              value: '${measurement.pointCount}',
              context: context,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final BuildContext context;

  const _StatRow({
    required this.label,
    required this.value,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.primary,
                ),
          ),
        ],
      ),
    );
  }
}

class _EvaluationsList extends StatelessWidget {
  final List<FieldEvaluation> evaluations;

  const _EvaluationsList({required this.evaluations});

  @override
  Widget build(BuildContext context) {
    if (evaluations.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Esta medición aún no tiene evaluaciones de campo.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Evaluaciones de campo',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final evaluation in evaluations) ...[
              _EvaluationTile(evaluation: evaluation),
              const Divider(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _EvaluationTile extends StatelessWidget {
  final FieldEvaluation evaluation;

  const _EvaluationTile({required this.evaluation});

  @override
  Widget build(BuildContext context) {
    final value = evaluation.referenceType == ReferenceType.area
        ? Formatters.formatArea(evaluation.referenceValue)
        : Formatters.formatDistance(evaluation.referenceValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Referencia: $value (${evaluation.referenceType.label})',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        if (evaluation.referenceSource != null)
          Text(
            'Fuente: ${evaluation.referenceSource}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        if (evaluation.envConditions != null)
          Text(
            'Condiciones: ${evaluation.envConditions}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}

class _DetailErrorView extends StatelessWidget {
  final String message;

  const _DetailErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colors.error),
            const SizedBox(height: 12),
            Text(
              'No se pudo cargar la medición.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailEmptyView extends StatelessWidget {
  const _DetailEmptyView();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: colors.primary),
          const SizedBox(height: 12),
          Text(
            'La medición solicitada no existe.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
