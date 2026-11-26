import 'package:flutter/material.dart';

import '../../domain/entities/geo_point.dart';
import '../../domain/usecases/geo/terrain_surface.dart';
import 'terrain_relief_3d_view.dart';
import 'terrain_relief_view.dart';

/// Vista de relieve con conmutador 2D/3D reutilizable.
///
/// Se usa tanto en la captura (sección de relieve sin conexión) como en el
/// detalle de una medición guardada. Genera la superficie 3D localmente a
/// partir de los puntos GNSS capturados, sin red ni DEM externos.
class TerrainReliefToggleView extends StatefulWidget {
  final List<GeoPoint> points;
  final List<GeoPoint> interiorPoints;
  final bool closePolygon;
  final double maxAccuracy;

  const TerrainReliefToggleView({
    super.key,
    required this.points,
    this.interiorPoints = const <GeoPoint>[],
    this.closePolygon = true,
    this.maxAccuracy = 20.0,
  });

  @override
  State<TerrainReliefToggleView> createState() => _TerrainReliefToggleViewState();
}

class _TerrainReliefToggleViewState extends State<TerrainReliefToggleView> {
  bool _is3D = false;
  double _exaggeration = 2.0;
  bool _showWireframe = false;
  bool _showContours = false;

  static const List<double> _exaggerationOptions = <double>[1.0, 2.0, 5.0, 10.0];

  TerrainSurface _buildSurface() {
    return TerrainSurfaceCalculator().fromPoints(
      [...widget.points, ...widget.interiorPoints],
      maxAccuracy: widget.maxAccuracy,
    );
  }

  int get _pointCount => widget.points.length + widget.interiorPoints.length;

  String get _densityHint {
    if (_pointCount < 5) {
      return 'Capture más puntos dentro del área para mejorar el relieve 3D.';
    }
    if (_pointCount < 10) {
      return 'Buena densidad. Capture más puntos interiores para mayor detalle.';
    }
    return 'Buena densidad de puntos para el relieve 3D.';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReliefViewToggle(
          is3D: _is3D,
          onChanged: (value) => setState(() => _is3D = value),
        ),
        const SizedBox(height: 4),
        // Guía de densidad de puntos.
        Text(
          '$_pointCount puntos capturados. $_densityHint',
          style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 4),
        if (_is3D) ...[
          _ExaggerationControl(
            value: _exaggeration,
            options: _exaggerationOptions,
            onChanged: (value) => setState(() => _exaggeration = value),
          ),
          const SizedBox(height: 2),
          // Toggle wireframe.
          Row(
            children: [
              Text('Malla (wireframe):', style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant)),
              const SizedBox(width: 8),
              Switch(
                value: _showWireframe,
                onChanged: (v) => setState(() => _showWireframe = v),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          const SizedBox(height: 2),
          // Toggle contours.
          Row(
            children: [
              Text('Curvas de nivel:', style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant)),
              const SizedBox(width: 8),
              Switch(
                value: _showContours,
                onChanged: (v) => setState(() => _showContours = v),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        Expanded(
          child: _is3D
              ? TerrainRelief3DView(
                  surface: _buildSurface(),
                  verticalExaggeration: _exaggeration,
                  showWireframe: _showWireframe,
                  showContours: _showContours,
                )
              : TerrainReliefView(
                  points: widget.points,
                  closePolygon: widget.closePolygon,
                  maxAccuracy: widget.maxAccuracy,
                ),
        ),
        if (!_is3D) ...[
          const SizedBox(height: 4),
          Text(
            'Representación aproximada: la altitud del GPS tiene menor precisión que la horizontal',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

class _ReliefViewToggle extends StatelessWidget {
  final bool is3D;
  final ValueChanged<bool> onChanged;

  const _ReliefViewToggle({
    required this.is3D,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ViewToggleButton(
              icon: Icons.terrain,
              label: '2D',
              selected: !is3D,
              onSelected: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _ViewToggleButton(
              icon: Icons.threed_rotation,
              label: '3D',
              selected: is3D,
              onSelected: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewToggleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _ViewToggleButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TextButton(
      onPressed: onSelected,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: selected ? colors.primary : colors.onSurfaceVariant,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: selected ? colors.primary : colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExaggerationControl extends StatelessWidget {
  final double value;
  final List<double> options;
  final ValueChanged<double> onChanged;

  const _ExaggerationControl({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        Text(
          'Exageración vertical:',
          style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
        ),
        for (final option in options)
          ChoiceChip(
            label: Text('${option.toStringAsFixed(0)}x'),
            selected: value == option,
            onSelected: (_) => onChanged(option),
          ),
      ],
    );
  }
}
