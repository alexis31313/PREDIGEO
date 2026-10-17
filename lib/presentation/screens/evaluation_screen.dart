// Pantalla de evaluación de campo: registra valores de referencia para una
// medición existente y muestra las evaluaciones ya registradas.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/field_evaluation.dart';
import '../../domain/entities/measurement.dart';
import '../../domain/entities/measurement_enums.dart';
import '../../presentation/providers/measurement_repository_provider.dart';
import 'results_screen.dart';

/// Orígenes posibles del valor de referencia, con su identificador estable
/// y su etiqueta legible.
const List<({String value, String label})> kReferenceSources = [
  (value: 'igac', label: 'IGAC'),
  (
    value: 'levantamiento_topografico',
    label: 'Levantamiento topográfico'
  ),
  (value: 'cinta_distanciometro', label: 'Cinta distanciómetro'),
];

/// Pantalla para registrar evaluaciones de campo sobre una medición.
///
/// Si no se indica [measurementId], permite seleccionar la medición desde el
/// historial. Las evaluaciones quedan persistidas en SQLite a través del
/// repositorio y alimentan el análisis de precisión de [ResultsScreen].
class EvaluationScreen extends ConsumerStatefulWidget {
  /// Medición a evaluar. `null` para elegirla desde el historial.
  final int? measurementId;

  const EvaluationScreen({super.key, this.measurementId});

  @override
  ConsumerState<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends ConsumerState<EvaluationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _conditionsController = TextEditingController();

  ReferenceType _referenceType = ReferenceType.area;
  String _referenceSource = kReferenceSources.first.value;
  Measurement? _selectedMeasurement;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedMeasurement = null;
  }

  @override
  void dispose() {
    _valueController.dispose();
    _conditionsController.dispose();
    super.dispose();
  }

  Future<void> _saveEvaluation() async {
    if (!_formKey.currentState!.validate()) return;
    final measurement = _selectedMeasurement;
    if (measurement == null) {
      _showSnackBar('Seleccione una medición para evaluar');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final evaluation = FieldEvaluation(
        measurementId: measurement.id!,
        referenceValue: double.parse(
          _valueController.text.trim().replaceAll(',', '.'),
        ),
        referenceType: _referenceType,
        referenceSource: _referenceSource,
        envConditions: _conditionsController.text.trim().isEmpty
            ? null
            : _conditionsController.text.trim(),
      );
      await ref
          .read(measurementRepositoryProvider)
          .insertEvaluation(evaluation);
      ref.invalidate(fieldEvaluationsProvider(measurement.id!));
      _valueController.clear();
      _conditionsController.clear();
      if (mounted) {
        _showSnackBar('Evaluación guardada correctamente');
      }
    } catch (error) {
      if (mounted) {
        _showSnackBar('Error al guardar: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evaluación de campo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: widget.measurementId != null
          ? _buildBody(widget.measurementId!)
          : _buildBodyWithSelector(),
    );
  }

  /// Cuerpo con selector de medición cuando no se recibe [measurementId].
  Widget _buildBodyWithSelector() {
    final history = ref.watch(measurementHistoryProvider);
    return history.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (measurements) {
        if (measurements.isEmpty) {
          return const Center(
            child: Text('No hay mediciones registradas para evaluar'),
          );
        }
        _selectedMeasurement ??= measurements.first;
        return _buildBody(_selectedMeasurement!.id!);
      },
    );
  }

  /// Formulario + listado de evaluaciones de la medición indicada.
  Widget _buildBody(int measurementId) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Registrar valor de referencia',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _valueController,
            decoration: InputDecoration(
              labelText: _referenceType == ReferenceType.area
                  ? 'Valor de referencia (m²)'
                  : 'Valor de referencia (m)',
              border: const OutlineInputBorder(),
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ingrese el valor de referencia';
              }
              final parsed =
                  double.tryParse(value.trim().replaceAll(',', '.'));
              if (parsed == null || parsed < 0) {
                return 'Ingrese un valor numérico válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ReferenceType>(
            value: _referenceType,
            decoration: const InputDecoration(
              labelText: 'Tipo de referencia',
              border: OutlineInputBorder(),
            ),
            items: ReferenceType.values
                .map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.label),
                  ),
                )
                .toList(),
            onChanged: (type) {
              if (type != null) {
                setState(() => _referenceType = type);
              }
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _referenceSource,
            decoration: const InputDecoration(
              labelText: 'Fuente del valor de referencia',
              border: OutlineInputBorder(),
            ),
            items: kReferenceSources
                .map(
                  (source) => DropdownMenuItem(
                    value: source.value,
                    child: Text(source.label),
                  ),
                )
                .toList(),
            onChanged: (source) {
              if (source != null) {
                setState(() => _referenceSource = source);
              }
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _conditionsController,
            decoration: const InputDecoration(
              labelText: 'Condiciones ambientales (opcional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _isSaving ? null : _saveEvaluation,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(_isSaving ? 'Guardando…' : 'Guardar evaluación'),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Evaluaciones registradas',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          _buildEvaluationsList(measurementId),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ResultsScreen(),
              ),
            ),
            icon: const Icon(Icons.bar_chart),
            label: const Text('Ver resultados de evaluación'),
          ),
        ],
      ),
    );
  }

  /// Listado de evaluaciones ya registradas para la medición.
  Widget _buildEvaluationsList(int measurementId) {
    final evaluations = ref.watch(fieldEvaluationsProvider(measurementId));
    return evaluations.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (items) {
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('Aún no hay evaluaciones registradas'),
            ),
          );
        }
        return Column(
          children: [
            for (final item in items)
              Card(
                child: ListTile(
                  leading: Icon(
                    item.referenceType == ReferenceType.area
                        ? Icons.square_foot
                        : Icons.straighten,
                  ),
                  title: Text(
                    '${item.referenceType.label}: '
                    '${item.referenceValue.toStringAsFixed(2)}',
                  ),
                  subtitle: Text(
                    [
                      if (item.referenceSource != null)
                        'Fuente: ${item.referenceSource}',
                      if (item.envConditions != null)
                        'Condiciones: ${item.envConditions}',
                    ].join('\n'),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
