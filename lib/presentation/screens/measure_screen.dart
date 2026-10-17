// Pantalla de nueva medición de PrediGeo.
// Flujo offline-first: captura puntos con PointCaptureService (filtrado y
// promedio configurados en Ajustes), calcula área/perímetro/distancia de
// forma local y guarda en SQLite. El mapa solo se muestra en modo conectado.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/geo_point.dart';
import '../../domain/entities/measurement.dart';
import '../../domain/entities/measurement_enums.dart';
import '../../domain/usecases/geo/area_calculator.dart';
import '../../domain/usecases/geo/distance_calculator.dart';
import '../../domain/usecases/geo/polygon_validator.dart';
import '../../domain/usecases/geo/slope_correction.dart';
import '../../domain/usecases/signal_processing/point_capture_service.dart';
import '../../core/utils/formatters.dart';
import '../providers/measurement_repository_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/measurement_map_view.dart';
import '../widgets/signal_indicator.dart';

class MeasureScreen extends ConsumerStatefulWidget {
  const MeasureScreen({super.key});

  @override
  ConsumerState<MeasureScreen> createState() => _MeasureScreenState();
}

class _MeasureScreenState extends ConsumerState<MeasureScreen> {
  MeasurementType _type = MeasurementType.area;
  final List<GeoPoint> _points = [];
  bool _capturing = false;
  double _progress = 0;
  String? _error;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  MeasurementCategory? _category;

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Captura un punto con filtrado y promedio según los ajustes.
  Future<void> _capturePoint() async {
    if (_capturing) return;
    setState(() {
      _capturing = true;
      _progress = 0;
      _error = null;
    });
    try {
      final service = ref.read(configuredCaptureServiceProvider);
      final samples = ref.read(captureSamplesProvider);
      final captured = await service.capturePoint(
        samples: samples,
        onProgress: (progress) {
          if (mounted) setState(() => _progress = progress);
        },
      );
      if (!mounted) return;
      setState(() {
        _points.add(
          GeoPoint(
            seq: _points.length,
            latitude: captured.latitude,
            longitude: captured.longitude,
            altitude: captured.altitude,
            accuracy: captured.estimatedAccuracy,
            timestamp: captured.timestamp,
          ),
        );
      });
    } on InsufficientSamplesException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Error al capturar el punto: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al capturar el punto: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _capturing = false;
          _progress = 0;
        });
      }
    }
  }

  void _removePoint(int index) {
    setState(() {
      _points.removeAt(index);
      for (var i = 0; i < _points.length; i++) {
        _points[i] = _points[i].copyWith(seq: i);
      }
    });
  }

  void _clearPoints() {
    setState(() => _points.clear());
  }

  double? get _area {
    if (_type != MeasurementType.area || _points.length < 3) return null;
    return AreaCalculator.fromGeoPoints(_points);
  }

  double? get _perimeter {
    if (_points.length < 2) return null;
    return DistanceCalculator.perimeter(_points);
  }

  double? get _distance {
    if (_type != MeasurementType.path || _points.length < 2) return null;
    return DistanceCalculator.pathLength(_points);
  }

  /// Área sobre el terreno (con relieve) a partir del área planimétrica.
  double? get _slopedArea {
    final plan = _area;
    if (plan == null) return null;
    return SlopeCorrection.slopedArea(plan, _points);
  }

  /// Distancia/perímetro sobre el terreno (3D con altitud).
  double? get _distance3D {
    if (_type != MeasurementType.path || _points.length < 2) return null;
    return DistanceCalculator.pathLength3D(_points);
  }

  double? get _perimeter3D {
    if (_points.length < 2) return null;
    return DistanceCalculator.perimeter3D(_points);
  }

  double? get _lastAccuracy =>
      _points.isEmpty ? null : _points.last.accuracy;

  /// Valida y guarda la medición en el historial local.
  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Asigna un nombre a la medición')),
      );
      return;
    }
    if (_type == MeasurementType.area) {
      if (_points.length < 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Un polígono necesita al menos 3 puntos'),
          ),
        );
        return;
      }
      final validation = PolygonValidator().validate(_points);
      if (!validation.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(validation.errors.first)),
        );
        return;
      }
    } else {
      if (_points.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Un trayecto necesita al menos 2 puntos'),
          ),
        );
        return;
      }
    }

    final settings = ref.read(settingsProvider);
    final avgAccuracy = _points.isEmpty
        ? null
        : _points.map((p) => p.accuracy).reduce((a, b) => a + b) /
            _points.length;
    final measurement = Measurement(
      name: name,
      type: _type,
      areaM2: _area,
      perimeterM: _type == MeasurementType.area ? _perimeter : null,
      distanceM: _type == MeasurementType.path ? _distance : _perimeter,
      mode: settings.operationMode,
      category: _category,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      avgAccuracyM: avgAccuracy,
      createdAt: DateTime.now(),
      points: List<GeoPoint>.from(_points),
    );

    await ref.read(measurementHistoryActionsProvider.notifier).save(measurement);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Medición guardada')),
    );
    context.go('/history');
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final online = settings.operationMode == MeasurementMode.online;
    final area = _area;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Medición'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Ajustes de medición',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tipo de medición',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<MeasurementType>(
                      segments: const [
                        ButtonSegment(
                          value: MeasurementType.area,
                          label: Text('Área'),
                          icon: Icon(Icons.square_foot),
                        ),
                        ButtonSegment(
                          value: MeasurementType.path,
                          label: Text('Trayecto'),
                          icon: Icon(Icons.route),
                        ),
                      ],
                      selected: {_type},
                      onSelectionChanged: (selected) {
                        setState(() => _type = selected.first);
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Modo: ${settings.operationMode.label} · '
                      '${settings.samplesPerPoint} muestras/punto · '
                      'umbral ${settings.gpsAccuracyThreshold.toStringAsFixed(1)} m',
                      style:
                          const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (online && _points.isNotEmpty)
              MeasurementMapView(
                points: _points,
                type: _type,
                online: true,
              ),
            if (online && _points.isNotEmpty) const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Puntos: ${_points.length}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        SignalIndicator(accuracy: _lastAccuracy),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_capturing)
                      Column(
                        children: [
                          LinearProgressIndicator(value: _progress),
                          const SizedBox(height: 4),
                          Text(
                            'Capturando… ${(_progress * 100).round()} %',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _capturing ? null : _capturePoint,
                            icon: const Icon(Icons.gps_fixed),
                            label: const Text('Capturar punto'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_sweep),
                          tooltip: 'Limpiar puntos',
                          onPressed: _points.isEmpty || _capturing
                              ? null
                              : _clearPoints,
                        ),
                      ],
                    ),
                    if (area != null && _slopedArea != null) ...[
                      const Divider(),
                      Text(
                        'Área planimétrica: '
                        '${ref.watch(formattedAreaProvider(area))}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Área sobre el terreno: '
                        '${ref.watch(formattedAreaProvider(_slopedArea!))}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Sin relieve: proyección horizontal. '
                        'Con relieve: incluye subidas y bajadas '
                        '(la altitud del GPS es aproximada).',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                    if (_type == MeasurementType.area &&
                        _perimeter != null &&
                        _perimeter3D != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Perímetro: ${Formatters.formatDistance(_perimeter!)} '
                        '· sobre el terreno: '
                        '${Formatters.formatDistance(_perimeter3D!)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                    if (_type == MeasurementType.path &&
                        _distance != null &&
                        _distance3D != null) ...[
                      const Divider(),
                      Text(
                        'Distancia horizontal: '
                        '${Formatters.formatDistance(_distance!)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Distancia sobre el terreno: '
                        '${Formatters.formatDistance(_distance3D!)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'La distancia sobre el terreno suma el desnivel '
                        'de cada tramo (√(d² + Δh²)).',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_points.isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    for (var i = 0; i < _points.length; i++)
                      ListTile(
                        leading: CircleAvatar(child: Text('${i + 1}')),
                        title: Text(
                          '${_points[i].latitude.toStringAsFixed(6)}, '
                          '${_points[i].longitude.toStringAsFixed(6)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: Text(
                          'Alt ${_points[i].altitude.toStringAsFixed(1)} m · '
                          '±${_points[i].accuracy.toStringAsFixed(1)} m',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed:
                              _capturing ? null : () => _removePoint(i),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la medición',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<MeasurementCategory?>(
                      value: _category,
                      decoration: const InputDecoration(
                        labelText: 'Categoría del terreno',
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
                      onChanged: (value) =>
                          setState(() => _category = value),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notas (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _capturing || _points.isEmpty ? null : _save,
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar medición'),
                      ),
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
