import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/measurement.dart';
import '../providers/measurement_repository_provider.dart';
import '../widgets/measurement_card.dart';

/// Pantalla del Historial de PrediGeo.
///
/// Obtiene las mediciones guardadas localmente a través del repositorio y las
/// presenta como lista desplazable. Cada medición navega al detalle para
/// revisar puntos, resultados y evaluaciones.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  Future<void> _refresh() async {
    ref.invalidate(measurementHistoryProvider);
  }

  Future<void> _openDetail(Measurement measurement) async {
    final id = measurement.id;
    if (id == null) return;
    await context.push('/history/$id');
  }

  @override
  Widget build(BuildContext context) {
    final measurements = ref.watch(measurementHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: measurements.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _HistoryErrorView(
          message: error.toString(),
          onRetry: _refresh,
        ),
        data: (measurements) {
          if (measurements.isEmpty) {
            return const _HistoryEmptyView();
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: measurements.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final measurement = measurements[index];
                return MeasurementCard(
                  key: ValueKey(measurement.id ?? index),
                  name: measurement.name,
                  date: measurement.createdAt,
                  area: measurement.areaM2 ?? 0,
                  distance: measurement.distanceM ?? 0,
                  type: measurement.type.label,
                  onTap: () => _openDetail(measurement),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _HistoryEmptyView extends StatelessWidget {
  const _HistoryEmptyView();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: colors.primary),
          const SizedBox(height: 12),
          Text(
            'Aún no hay mediciones guardadas.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Las mediciones capturadas y guardadas aparecerán aquí.',
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

class _HistoryErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _HistoryErrorView({required this.message, required this.onRetry});

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
              'No se pudo cargar el historial.',
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
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                onRetry();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
