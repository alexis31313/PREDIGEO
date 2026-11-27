// Cámara orbital y proyección en perspectiva para la vista 3D del relieve.

import 'dart:math' as math;
import 'dart:ui';

/// Estado de la cámara orbital alrededor del centro del terreno.
class TerrainCamera {
  /// Rotación horizontal (rad). Con 0 el norte queda hacia el fondo.
  final double azimuth;

  /// Ángulo de la cámara sobre el horizonte (rad). π/2 = vista cenital.
  final double elevation;

  /// Factor de acercamiento (1 = el terreno completo cabe en la vista).
  final double zoom;

  /// Desplazamiento en pantalla (px).
  final Offset pan;

  static const double minElevation = 0.12;
  static const double maxElevation = 1.55;
  static const double minZoom = 0.4;
  static const double maxZoom = 6.0;

  static const TerrainCamera initial = TerrainCamera(
    azimuth: -0.55,
    elevation: 0.62,
    zoom: 1.0,
    pan: Offset.zero,
  );

  const TerrainCamera({
    required this.azimuth,
    required this.elevation,
    required this.zoom,
    required this.pan,
  });

  TerrainCamera copyWith({
    double? azimuth,
    double? elevation,
    double? zoom,
    Offset? pan,
  }) {
    return TerrainCamera(
      azimuth: azimuth ?? this.azimuth,
      elevation:
          (elevation ?? this.elevation).clamp(minElevation, maxElevation),
      zoom: (zoom ?? this.zoom).clamp(minZoom, maxZoom),
      pan: pan ?? this.pan,
    );
  }

  /// Dirección (mundo) desde la escena hacia la cámara.
  (double, double, double) get towardViewer {
    final sinA = math.sin(azimuth), cosA = math.cos(azimuth);
    final sinE = math.sin(elevation), cosE = math.cos(elevation);
    return (-sinA * cosE, -cosA * cosE, sinE);
  }

  @override
  bool operator ==(Object other) =>
      other is TerrainCamera &&
      other.azimuth == azimuth &&
      other.elevation == elevation &&
      other.zoom == zoom &&
      other.pan == pan;

  @override
  int get hashCode => Object.hash(azimuth, elevation, zoom, pan);
}

/// Proyección de coordenadas del mundo (m) a pantalla para un cuadro.
///
/// Sistema del mundo: x = este, y = norte, z = arriba. La escena se centra
/// en ([cx], [cy], [cz]) y se encuadra para que una esfera de radio [radius]
/// ocupe ~90 % del lado menor de la vista con zoom 1.
class TerrainProjection {
  final TerrainCamera camera;
  final Size size;
  final double cx, cy, cz;
  final double radius;

  late final double _sinA = math.sin(camera.azimuth);
  late final double _cosA = math.cos(camera.azimuth);
  late final double _sinE = math.sin(camera.elevation);
  late final double _cosE = math.cos(camera.elevation);

  /// Distancia de la cámara al centro de la escena.
  late final double distance = radius * 3.0;

  /// Distancia focal en píxeles.
  late final double focal =
      math.min(size.width, size.height) * 0.45 * distance / radius * camera.zoom;

  TerrainProjection({
    required this.camera,
    required this.size,
    required this.cx,
    required this.cy,
    required this.cz,
    required double radius,
  }) : radius = radius > 0 ? radius : 1.0;

  /// Proyecta un punto. Devuelve (x pantalla, y pantalla, distancia a la
  /// cámara). Una distancia mayor significa más lejos.
  (double, double, double) project(double x, double y, double z) {
    final dx = x - cx;
    final dy = y - cy;
    final dz = z - cz;
    final right = dx * _cosA - dy * _sinA;
    final forward = dx * _sinA + dy * _cosA;
    final up = dz * _cosE + forward * _sinE;
    final away = forward * _cosE - dz * _sinE;
    final dist = math.max(distance + away, distance * 0.05);
    final f = focal / dist;
    return (
      size.width / 2 + camera.pan.dx + right * f,
      size.height / 2 + camera.pan.dy - up * f,
      dist,
    );
  }
}
