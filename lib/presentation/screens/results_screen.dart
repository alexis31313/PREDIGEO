// Pantalla de resultados de la evaluación de precisión.
//
// Construye el informe a partir de todas las mediciones con evaluaciones de
// campo registradas y muestra tablas de RMSE y error porcentual por
// categoría y modalidad, gráficos de barras, la prueba t en línea vs sin
// conexión y la exportación a CSV.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/measurement_enums.dart';
import '../../domain/repositories/measurement_repository.dart';
import '../../domain/usecases/evaluation/evaluation_export.dart';
import '../../domain/usecases/evaluation/precision_analyzer.dart';
import '../../presentation/providers/measurement_repository_provider.dart';

/// Presenta los resultados del análisis de precisión de PrediGeo.
class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  EvaluationReport? _report;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  /// Carga todas las mediciones con sus evaluaciones y construye el informe.
  Future<void> _loadReport() async {
    try {
      final repository = ref.read(measurementRepositoryProvider);
      final history = await repository.getAll();
      final pairs = <EvaluationPair>[];

      for (final summary in history) {
        final measurement = await repository.getById(summary.id!);
        if (measurement == null || measurement.category == null) continue;
        for (final evaluation in measurement.evaluations) {
          final measured = evaluation.referenceType == ReferenceType.area
              ? measurement.areaM2
              : measurement.distanceM;
          if (measured == null) continue;
          pairs.add(
            EvaluationPair(
              measuredValue: measured,
              referenceValue: evaluation.referenceValue,
              category: measurement.category!,
              mode: measurement.mode,
            ),
          );
        }
      }

      setState(() {
        _report = const PrecisionAnalyzer().analyze(pairs);
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _exportToCsv() async {
    final report = _report;
    if (report == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final path = await const EvaluationExport().exportToCSV(report);
      messenger.showSnackBar(
        SnackBar(content: Text('CSV exportado en: $path')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error al exportar: $error')),
      );
    }
  }

  String _categoryLabel(String value) {
    for (final category in MeasurementCategory.values) {
      if (category.value == value) return category.label;
    }
    return value;
  }

  String _modeLabel(String value) {
    for (final mode in MeasurementMode.values) {
      if (mode.value == value) return mode.label;
    }
    return value;
  }

  /// Error porcentual medio de un grupo de pares.
  double _meanPercentError(List<EvaluationPair> pairs) {
    if (pairs.isEmpty) return 0;
    var sum = 0.0;
    for (final pair in pairs) {
      sum += pair.percentError;
    }
    return sum / pairs.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados de Evaluación'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exportar a CSV',
            onPressed: _report == null ? null : _exportToCsv,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    final report = _report!;
    if (report.pairs.isEmpty) {
      return const Center(
        child: Text(
          'No hay evaluaciones registradas.\n'
          'Registra valores de referencia desde la pantalla de evaluación.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryCard(report),
        const SizedBox(height: 16),
        _buildTTestCard(report),
        const SizedBox(height: 16),
        _buildStatsTable(
          title: 'RMSE por categoría de terreno',
          headers: const ['Categoría', 'n', 'RMSE', 'Error medio', 'Error máx.'],
          rows: [
            for (final entry in report.byCategory.entries)
              [
                _categoryLabel(entry.key),
                '${entry.value.n}',
                entry.value.rmse.toStringAsFixed(4),
                entry.value.mean.toStringAsFixed(4),
                entry.value.maxError.toStringAsFixed(4),
              ],
          ],
        ),
        const SizedBox(height: 16),
        _buildStatsTable(
          title: 'RMSE por modalidad de captura',
          headers: const ['Modalidad', 'n', 'RMSE', 'Error medio', 'Error máx.'],
          rows: [
            for (final entry in report.byMode.entries)
              [
                _modeLabel(entry.key),
                '${entry.value.n}',
                entry.value.rmse.toStringAsFixed(4),
                entry.value.mean.toStringAsFixed(4),
                entry.value.maxError.toStringAsFixed(4),
              ],
          ],
        ),
        const SizedBox(height: 16),
        _buildStatsTable(
          title: 'Error porcentual por categoría de terreno',
          headers: const ['Categoría', 'Error % medio'],
          rows: [
            for (final category in MeasurementCategory.values)
              [
                category.label,
                _meanPercentError(
                  report.pairs
                      .where((p) => p.category == category)
                      .toList(),
                ).toStringAsFixed(2),
              ],
          ],
        ),
        const SizedBox(height: 16),
        _buildStatsTable(
          title: 'Error porcentual por modalidad de captura',
          headers: const ['Modalidad', 'Error % medio'],
          rows: [
            for (final mode in MeasurementMode.values)
              [
                mode.label,
                _meanPercentError(
                  report.pairs.where((p) => p.mode == mode).toList(),
                ).toStringAsFixed(2),
              ],
          ],
        ),
        const SizedBox(height: 16),
        _buildRmseBarChart(
          title: 'RMSE por categoría de terreno',
          data: {
            for (final entry in report.byCategory.entries)
              _categoryLabel(entry.key): entry.value.rmse,
          },
        ),
        const SizedBox(height: 16),
        _buildRmseBarChart(
          title: 'RMSE por modalidad de captura',
          data: {
            for (final entry in report.byMode.entries)
              _modeLabel(entry.key): entry.value.rmse,
          },
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _exportToCsv,
          icon: const Icon(Icons.download),
          label: const Text('Exportar a CSV'),
        ),
      ],
    );
  }

  /// Tarjetas con las métricas globales del informe.
  Widget _buildSummaryCard(EvaluationReport report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen general',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Pares evaluados: ${report.pairs.length}'),
            Text('RMSE global: ${report.overallRMSE.toStringAsFixed(4)}'),
            Text(
              'Error medio global: '
              '${report.overallMeanError.toStringAsFixed(4)}',
            ),
          ],
        ),
      ),
    );
  }

  /// Resultado de la prueba t entre capturas en línea y sin conexión.
  Widget _buildTTestCard(EvaluationReport report) {
    final tTest = report.onlineVsOffline;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prueba t: en línea vs sin conexión',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (tTest == null)
              const Text(
                'No hay suficientes datos para la prueba t '
                '(se requieren al menos 2 pares por modalidad).',
              )
            else ...[
              Text('Estadístico t: ${tTest.tStatistic.toStringAsFixed(4)}'),
              Text('Grados de libertad: '
                  '${tTest.degreesOfFreedom.toStringAsFixed(1)}'),
              Text('Valor p: ${tTest.pValue.toStringAsFixed(4)}'),
              const SizedBox(height: 4),
              Text(
                tTest.isSignificant
                    ? 'Diferencia estadísticamente significativa (p < 0.05)'
                    : 'No se encontró diferencia significativa (p ≥ 0.05)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: tTest.isSignificant
                      ? Colors.orange.shade800
                      : Colors.green.shade800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Tabla de estadísticas con encabezado y filas formateadas.
  Widget _buildStatsTable({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  for (final header in headers)
                    DataColumn(label: Text(header)),
                ],
                rows: [
                  for (final row in rows)
                    DataRow(
                      cells: [
                        for (final cell in row) DataCell(Text(cell)),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Gráfico de barras del RMSE para cada grupo.
  Widget _buildRmseBarChart({
    required String title,
    required Map<String, double> data,
  }) {
    final entries = data.entries.toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 240,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: entries.isEmpty
                      ? 1
                      : entries
                              .map((e) => e.value)
                              .reduce((a, b) => a > b ? a : b) *
                          1.2,
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= entries.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              entries[index].key,
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    for (var i = 0; i < entries.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: entries[i].value,
                            width: 28,
                            borderRadius: BorderRadius.circular(4),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
