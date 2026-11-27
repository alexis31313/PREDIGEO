import 'package:flutter/material.dart';

import '../../domain/entities/geo_point.dart';
import '../../domain/usecases/geo/terrain_surface.dart';
import 'terrain_relief_3d_view.dart';
import 'terrain_relief_view.dart';

/// Vista de relieve con conmutador 2D/3D reutilizable.
///
/// Se usa tanto en la captura (sección de relieve) como en el detalle de una
/// medición guardada. Genera la superficie 3D localmente a partir de los
/// puntos GNSS capturados (contorno + interior), sin red ni DEM externos.
class TerrainReliefToggleView extends StatefulWidget {
  final List<GeoPoint> points;
  final List<GeoPoint> interiorPoints;
  final bool closePolygon;
  final double maxAccuracy;

  /// Abre directamente en modo 3D.
  final bool initialIs3D;

  /// Muestra el botón para abrir la vista en pantalla completa.
  final bool allowFullscreen;

  const TerrainReliefToggleView({
    super.key,
    required this.points,
    this.interiorPoints = const <GeoPoint>[],
    this.closePolygon = true,
    this.maxAccuracy = 20.0,
    this.initialIs3D = false,
    this.allowFullscreen = true,
  });

  @override
  State<TerrainReliefToggleView> createState() =>
      _TerrainReliefToggleViewState();
}

class _TerrainReliefToggleViewState extends State<TerrainReliefToggleView> {
  late bool _is3D = widget.initialIs3D;

  /// `null` = exageración automática.
  double? _exaggeration;
  bool _showWireframe = false;
  bool _showContours = false;
  bool _smooth = false;

  static const List<double> _exaggerationOptions = <double>[1, 2, 5, 10, 20];

  TerrainSurface? _surface;
  List<GeoPoint>? _surfacePoints;
  List<GeoPoint>? _surfaceInterior;
  bool? _surfaceClosed;
  double? _surfaceAccuracy;

  /// Recalcula la superficie solo cuando cambian los datos de entrada.
  TerrainSurface get _currentSurface {
    final cached = _surface;
    if (cached != null &&
        identical(_surfacePoints, widget.points) &&
        identical(_surfaceInterior, widget.interiorPoints) &&
        _surfaceClosed == widget.closePolygon &&
        _surfaceAccuracy == widget.maxAccuracy) {
      return cached;
    }
    _surfacePoints = widget.points;
    _surfaceInterior = widget.interiorPoints;
    _surfaceClosed = widget.closePolygon;
    _surfaceAccuracy = widget.maxAccuracy;
    return _surface = TerrainSurfaceCalculator().fromPoints(
      widget.points,
      interiorPoints: widget.interiorPoints,
      maxAccuracy: widget.maxAccuracy,
      clipToBoundary: widget.closePolygon && widget.points.length >= 3,
    );
  }

  int get _pointCount => widget.points.length + widget.interiorPoints.length;

  String get _densityHint {
    if (_pointCount < 5) {
      return 'Capture puntos dentro del área para mejorar el relieve 3D.';
    }
    if (_pointCount < 10) {
      return 'Buena densidad. Más puntos interiores darán más detalle.';
    }
    return 'Buena densidad de puntos para el relieve 3D.';
  }

  void _openFullscreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => TerrainRelief3DScreen(
          points: widget.points,
          interiorPoints: widget.interiorPoints,
          closePolygon: widget.closePolygon,
          maxAccuracy: widget.maxAccuracy,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hintStyle = TextStyle(
      fontSize: 10,
      color: colors.onSurfaceVariant,
      fontStyle: FontStyle.italic,
    );
    final interiorCount = widget.interiorPoints.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _ReliefViewToggle(
                is3D: _is3D,
                onChanged: (value) => setState(() => _is3D = value),
              ),
            ),
            if (widget.allowFullscreen) ...[
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Ver relieve 3D en pantalla completa',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.open_in_full, size: 20),
                onPressed: _openFullscreen,
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _is3D
              ? '$_pointCount puntos ($interiorCount interiores) · '
                  '1 dedo: rotar · 2 dedos: zoom y mover'
              : '$_pointCount puntos capturados. $_densityHint',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: hintStyle,
        ),
        if (_is3D) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _ExaggerationMenu(
                value: _exaggeration,
                options: _exaggerationOptions,
                onChanged: (value) => setState(() => _exaggeration = value),
              ),
              _OptionChip(
                label: 'Malla',
                selected: _showWireframe,
                onChanged: (v) => setState(() => _showWireframe = v),
              ),
              _OptionChip(
                label: 'Curvas',
                selected: _showContours,
                onChanged: (v) => setState(() => _showContours = v),
              ),
              _OptionChip(
                label: 'Suavizar',
                selected: _smooth,
                onChanged: (v) => setState(() => _smooth = v),
              ),
            ],
          ),
        ],
        const SizedBox(height: 4),
        Expanded(
          child: _is3D
              ? TerrainRelief3DView(
                  surface: _currentSurface,
                  verticalExaggeration: _exaggeration,
                  showWireframe: _showWireframe,
                  showContours: _showContours,
                  smooth: _smooth,
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
            terrainAccuracyDisclaimer,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

/// Pantalla completa con la vista 3D del relieve.
class TerrainRelief3DScreen extends StatelessWidget {
  final List<GeoPoint> points;
  final List<GeoPoint> interiorPoints;
  final bool closePolygon;
  final double maxAccuracy;

  const TerrainRelief3DScreen({
    super.key,
    required this.points,
    this.interiorPoints = const <GeoPoint>[],
    this.closePolygon = true,
    this.maxAccuracy = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Relieve 3D')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: TerrainReliefToggleView(
            points: points,
            interiorPoints: interiorPoints,
            closePolygon: closePolygon,
            maxAccuracy: maxAccuracy,
            initialIs3D: true,
            allowFullscreen: false,
          ),
        ),
      ),
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
    final color = selected ? colors.primary : colors.onSurfaceVariant;
    return TextButton(
      onPressed: onSelected,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        backgroundColor:
            selected ? colors.primaryContainer.withValues(alpha: 0.5) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onChanged;

  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: selected,
      onSelected: onChanged,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 2),
    );
  }
}

class _ExaggerationMenu extends StatelessWidget {
  final double? value;
  final List<double> options;
  final ValueChanged<double?> onChanged;

  const _ExaggerationMenu({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  static String _label(double? v) =>
      v == null ? 'Auto' : '${v.toStringAsFixed(0)}x';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return PopupMenuButton<double>(
      tooltip: 'Exageración vertical',
      // -1 representa "automática" dentro del menú.
      onSelected: (selected) => onChanged(selected < 0 ? null : selected),
      itemBuilder: (_) => <PopupMenuEntry<double>>[
        CheckedPopupMenuItem<double>(
          value: -1,
          checked: value == null,
          child: const Text('Auto'),
        ),
        for (final option in options)
          CheckedPopupMenuItem<double>(
            value: option,
            checked: value == option,
            child: Text(_label(option)),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.height, size: 14, color: colors.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              'Exageración: ${_label(value)}',
              style: const TextStyle(fontSize: 11),
            ),
            const Icon(Icons.arrow_drop_down, size: 16),
          ],
        ),
      ),
    );
  }
}
