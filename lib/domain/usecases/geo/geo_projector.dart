import 'dart:math' as math;
import '../../entities/geo_point.dart';
import './point2d.dart';

class GeoProjector {
  static const double a = 6378137.0;
  static const double f = 1.0 / 298.257222101;
  static const double degToRad = 1.7453292519943295769236907684886e-2;

  final GeoPoint _origin;
  final double _lat0Rad;
  final double _lon0Rad;
  final double _r;

  GeoProjector(this._origin)
      : _lat0Rad = _origin.latitude * degToRad,
        _lon0Rad = _origin.longitude * degToRad,
        _r = _computePrimeVerticalRadius(_origin.latitude * degToRad);

  static double _computePrimeVerticalRadius(double latRad) {
    final sinLat = math.sin(latRad);
    final sin2 = sinLat * sinLat;
    final e2 = 2.0 * f - f * f;
    final denom = 1.0 - e2 * sin2;
    return a / math.sqrt(denom);
  }

  Point2D project(GeoPoint point) {
    final latRad = point.latitude * degToRad;
    final lonRad = point.longitude * degToRad;
    final cosLat0 = math.cos(_lat0Rad);
    final x = _r * cosLat0 * (lonRad - _lon0Rad);
    final y = _r * (latRad - _lat0Rad);
    return Point2D(x, y);
  }

  List<Point2D> projectList(List<GeoPoint> points) {
    return points.map(project).toList();
  }

  GeoPoint get origin => _origin;
}
