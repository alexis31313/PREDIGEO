import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../domain/entities/field_evaluation.dart';
import '../../domain/entities/measurement.dart';
import '../../domain/entities/measurement_enums.dart';
import '../providers/measurement_repository_provider.dart';

/// Pantalla de Evaluación de PrediGeo.
///
/// Resume las mediciones guardadas (conteo, áreas, trayectos) y lista las
/// evaluaciones de campo asociadas a cada medición.
class EvaluationScreen extends ConsumerStatefulWidget {
  const EvaluationScreen({super.key});

  @override
  ConsumerState<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends ConsumerState<EvaluationScreen> {
  @override
  Widget build(BuildContext context) {
    final measurements = ref.watch(measurementsWithEvaluationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evaluación'),
      ),
      body: measurements.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _EvaluationErrorView(message: error.toString()),
        data: (measurements) => _EvaluationContent(measurements: measurements),
      ),
    );
  }
}

class _EvaluationContent extends StatelessWidget {
  final List<Measurement> measurements;

  const _EvaluationContent({required this.measurements});

  double get _totalArea {
    return measurements.fold<double>(
      0.0,
      (sum, measurement) =>
          sum + (measurement.isArea ? (measurement.areaM2 ?? 0.0) : 0.0),
    );
  }

  double get _totalDistance {
    return measurements.fold<double>(
      0.0,
      (sum, measurement) =>
          sum + (measurement.isPath ? (measurement.distanceM ?? 0.0) : 0.0),
    );
  }

  List<Measurement> get _areaMeasurements =>
      measurements
          .where((measurement) => measurement.isArea)
          .where((measurement) => (measurement.areaM2 ?? 0) > 0)
          .toList();

  List<Measurement> get _pathMeasurements => measurements
      .where((measurement) => measurement.isPath)
      .where((measurement) => (measurement.distanceM ?? 0) > 0)
      .toList();

  @override
  Widget build(BuildContext context) {
    if (measurements.isEmpty) {
      return const _EvaluationEmptyView();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ..._statTiles(context),
        const SizedBox(height: 20),
        const Text(
          'Evaluaciones de campo',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ..._buildEvaluations(context, measurements),
      ],
    );
  }

  List<Widget> _buildEvaluations(BuildContext context, List<Measurement> measurements) {
    final items = <Widget>[];
    for (final measurement in measurements) {
      for (final evaluation in measurement.evaluations) {
        items.add(_EvaluationItem(measurement: measurement, evaluation: evaluation));
      }
    }

    if (items.isEmpty) {
      return [
        const _EvaluationsEmpty(),
      ];
    }
    return items;
  }

  List<Widget> _statTiles(BuildContext context) {
    final tiles = <Widget>[
      _StatTile(
        icon: Icons.assignment,
        label: 'Mediciones guardadas',
        value: '${measurements.length}',
      ),
    ];
    if (_areaMeasurements.isNotEmpty) {
      tiles.add(
        _StatTile(
          icon: Icons.square_foot,
          label: 'Área total medida',
          value: Formatters.formatArea(_totalArea),
        ),
      );
      final averageArea =
          _totalArea / _areaMeasurements.length;
      tiles.add(
        _StatTile(
          icon: Icons.calculate,
          label: 'Área promedio',
          value: Formatters.formatArea(averageArea),
        ),
      );
    }
    if (_pathMeasurements.isNotEmpty) {
      tiles.add(
        _StatTile(
          icon: Icons.straighten,
          label: 'Distancia total recorrida',
          value: Formatters.formatDistance(_totalDistance),
        ),
      );
    }

    return [
      ...tiles.map(
        (tile) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: tile,
        ),
      ),
      const SizedBox(height: 16),
    ];
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.onPrimaryContainer,
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

class _EvaluationItem extends StatelessWidget {
  final Measurement measurement;
  final FieldEvaluation evaluation;

  const _EvaluationItem({
    required this.measurement,
    required this.evaluation,
  });

  @override
  Widget build(BuildContext context) {
    final value = evaluation.referenceType == ReferenceType.area
        ? Formatters.formatArea(evaluation.referenceValue)
        : Formatters.formatDistance(evaluation.referenceValue);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              measurement.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Referencia: $value (${evaluation.referenceType.label})',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (evaluation.referenceSource != null) ...[
              const SizedBox(height: 2),
              Text(
                'Fuente: ${evaluation.referenceSource}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (evaluation.envConditions != null) ...[
              const SizedBox(height: 2),
              Text(
                'Condiciones: ${evaluation.envConditions}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EvaluationsEmpty extends StatelessWidget {
  const _EvaluationsEmpty();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.assignment_outlined, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Aún no hay evaluaciones de campo registradas.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _EvaluationEmptyView extends StatelessWidget {
  const _EvaluationEmptyView();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assessment_outlined, size: 64, color: colors.primary),
          const SizedBox(height: 12),
          Text(
            'Aún no hay datos para evaluar.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Las mediciones y evaluaciones guardadas aparecerán aquí.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EvaluationErrorView extends StatelessWidget {
  final String message;

  const _EvaluationErrorView({required this.message});

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
              'No se pudo cargar la evaluación.',
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
