class Point2D {
  final double x;
  final double y;

  const Point2D(this.x, this.y);

  Point2D copyWith({double? x, double? y}) {
    return Point2D(x ?? this.x, y ?? this.y);
  }

  static double distance(Point2D a, Point2D b) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    return _sqrt(dx * dx + dy * dy);
  }

  static double _sqrt(double value) {
    if (value <= 0) return 0;
    double x = value;
    double y = (x + 1) / 2;
    while (y < x) {
      x = y;
      y = (x + value / x) / 2;
    }
    return x;
  }

  @override
  String toString() => 'Point2D(x: $x, y: $y)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Point2D && other.x == x && other.y == y;
  }

  @override
  int get hashCode => Object.hash(x, y);
}
