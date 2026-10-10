import '../../entities/geo_point.dart';
import './point2d.dart';
import './geo_projector.dart';

class AreaCalculator {
  static double shoelace(List<Point2D> points) {
    if (points.length < 3) return 0.0;
    double sum = 0.0;
    for (int i = 0; i < points.length; i++) {
      final j = (i + 1) % points.length;
      sum += points[i].x * points[j].y;
      sum -= points[j].x * points[i].y;
    }
    return (sum.abs()) / 2.0;
  }

  static double fromGeoPoints(List<GeoPoint> points) {
    if (points.length < 3) return 0.0;
    double latSum = 0.0;
    double lonSum = 0.0;
    for (final p in points) {
      latSum += p.latitude;
      lonSum += p.longitude;
    }
    final centroid = GeoPoint(
      seq: 0,
      latitude: latSum / points.length,
      longitude: lonSum / points.length,
      altitude: 0.0,
      accuracy: 0.0,
      timestamp: points.first.timestamp,
    );
    final projector = GeoProjector(centroid);
    final projected = projector.projectList(points);
    return shoelace(projected);
  }

  static double perimeter(List<Point2D> points) {
    if (points.length < 2) return 0.0;
    double total = 0.0;
    for (int i = 0; i < points.length; i++) {
      final j = (i + 1) % points.length;
      total += Point2D.distance(points[i], points[j]);
    }
    return total;
  }
}
