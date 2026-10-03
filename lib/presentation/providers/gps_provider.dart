// Proveedores de Riverpod para el estado del GPS:
// stream de estado, lista de coordenadas, tracking y filtrado.

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum GpsStatus { unavailable, searching, active, error }

class Coordinate {
  final double latitude;
  final double longitude;
  final double? altitude;
  final DateTime timestamp;

  const Coordinate({
    required this.latitude,
    required this.longitude,
    this.altitude,
    required this.timestamp,
  });
}

final gpsStatusProvider = StreamProvider<GpsStatus>((ref) async* {
  yield GpsStatus.searching;
  await Future.delayed(const Duration(seconds: 1));
  yield GpsStatus.active;
});

class CoordinateNotifier extends StateNotifier<List<Coordinate>> {
  CoordinateNotifier() : super([]);

  void addCoordinate(Coordinate coordinate) {
    state = [...state, coordinate];
  }

  void clear() {
    state = [];
  }

  int get count => state.length;
}

final coordinateListProvider =
    StateNotifierProvider<CoordinateNotifier, List<Coordinate>>((ref) {
  return CoordinateNotifier();
});

final isTrackingProvider = StateProvider<bool>((ref) => false);

final filteredCoordinatesProvider = Provider<List<Coordinate>>((ref) {
  final coordinates = ref.watch(coordinateListProvider);
  final isTracking = ref.watch(isTrackingProvider);

  if (!isTracking || coordinates.isEmpty) {
    return coordinates;
  }

  final filtered = <Coordinate>[];
  const minDistanceMeters = 1.0;

  for (final coord in coordinates) {
    if (filtered.isEmpty) {
      filtered.add(coord);
      continue;
    }

    final last = filtered.last;
    final latDiff = (coord.latitude - last.latitude).abs() * 111320;
    final lonDiff = (coord.longitude - last.longitude).abs() *
        111320 *
        _cosDegrees(coord.latitude);
    final distance = _sqrt(latDiff * latDiff + lonDiff * lonDiff);

    if (distance >= minDistanceMeters) {
      filtered.add(coord);
    }
  }

  return filtered;
});

double _cosDegrees(double degrees) {
  return _cos(degrees * 3.141592653589793 / 180.0);
}

double _cos(double radians) {
  return 1.0 -
      (radians * radians) / 2.0 +
      (radians * radians * radians * radians) / 24.0;
}

double _sqrt(double value) {
  if (value <= 0) return 0;
  double x = value;
  double y = (x + 1) / 2;
  while (y < x) {
    x = y;
    y = (x + value / x) / 2;
  }
  return x;
}
