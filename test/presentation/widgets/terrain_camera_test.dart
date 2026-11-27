import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:predigeo/presentation/widgets/terrain_camera.dart';

void main() {
  TerrainProjection projection(TerrainCamera camera) => TerrainProjection(
        camera: camera,
        size: const Size(400, 300),
        cx: 0,
        cy: 0,
        cz: 0,
        radius: 50,
      );

  const oblique = TerrainCamera(
    azimuth: 0,
    elevation: 0.5,
    zoom: 1,
    pan: Offset.zero,
  );

  double segmentLength(TerrainProjection p, double y) {
    final (ax, _, _) = p.project(-5, y, 0);
    final (bx, _, _) = p.project(5, y, 0);
    return (bx - ax).abs();
  }

  test('lo cercano se ve más grande que lo lejano (perspectiva correcta)', () {
    final p = projection(oblique);
    // Con azimut 0 el norte (+y) queda al fondo.
    final near = segmentLength(p, -30);
    final far = segmentLength(p, 30);
    expect(near, greaterThan(far));

    final (_, _, nearDist) = p.project(0, -30, 0);
    final (_, _, farDist) = p.project(0, 30, 0);
    expect(nearDist, lessThan(farDist));
  });

  test('los puntos más altos quedan más arriba en pantalla', () {
    final p = projection(oblique);
    final (_, lowY, _) = p.project(0, 0, 0);
    final (_, highY, _) = p.project(0, 0, 10);
    expect(highY, lessThan(lowY));
  });

  test('en vista cenital el norte queda arriba y el este a la derecha', () {
    final p = projection(
      const TerrainCamera(
        azimuth: 0,
        elevation: math.pi / 2,
        zoom: 1,
        pan: Offset.zero,
      ),
    );
    final (cx, cy, _) = p.project(0, 0, 0);
    final (_, northY, _) = p.project(0, 20, 0);
    final (eastX, _, _) = p.project(20, 0, 0);
    expect(northY, lessThan(cy));
    expect(eastX, greaterThan(cx));
  });

  test('el centro de la escena se proyecta al centro de la vista', () {
    final (x, y, _) = projection(oblique).project(0, 0, 0);
    expect(x, closeTo(200, 1e-9));
    expect(y, closeTo(150, 1e-9));
  });

  test('el zoom amplía y la cámara respeta sus límites', () {
    final base = segmentLength(projection(oblique), 0);
    final zoomed = segmentLength(projection(oblique.copyWith(zoom: 2)), 0);
    expect(zoomed, closeTo(base * 2, 1e-6));

    final clamped = oblique.copyWith(elevation: -3, zoom: 100);
    expect(clamped.elevation, TerrainCamera.minElevation);
    expect(clamped.zoom, TerrainCamera.maxZoom);
  });

  test('la dirección hacia el observador apunta hacia la cámara', () {
    final (vx, vy, vz) = oblique.towardViewer;
    // Con azimut 0 la cámara está al sur (−y) y por encima (+z).
    expect(vx.abs(), lessThan(1e-9));
    expect(vy, lessThan(0));
    expect(vz, greaterThan(0));
  });
}
