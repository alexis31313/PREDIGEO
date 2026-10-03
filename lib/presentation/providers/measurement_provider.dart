// Proveedores de Riverpod para la gestión de mediciones:
// listado, detalle, operaciones CRUD y estado del formulario.

import 'package:flutter_riverpod/flutter_riverpod.dart';

class Measurement {
  final String id;
  final String name;
  final DateTime date;
  final double area;
  final double distance;
  final String type;

  const Measurement({
    required this.id,
    required this.name,
    required this.date,
    required this.area,
    required this.distance,
    required this.type,
  });
}

class MeasurementFormState {
  final String name;
  final String type;
  final bool isSubmitting;
  final String? errorMessage;

  const MeasurementFormState({
    this.name = '',
    this.type = 'Polígono',
    this.isSubmitting = false,
    this.errorMessage,
  });

  MeasurementFormState copyWith({
    String? name,
    String? type,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return MeasurementFormState(
      name: name ?? this.name,
      type: type ?? this.type,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final measurementListProvider = FutureProvider<List<Measurement>>((ref) async {
  return [];
});

final measurementDetailProvider =
    FutureProvider.family<Measurement?, String>((ref, id) async {
  return null;
});

class MeasurementNotifier extends StateNotifier<List<Measurement>> {
  MeasurementNotifier() : super([]);

  Future<void> loadMeasurements() async {
    state = [];
  }

  Future<void> addMeasurement(Measurement measurement) async {
    state = [...state, measurement];
  }

  Future<void> updateMeasurement(Measurement measurement) async {
    state = state
        .map((m) => m.id == measurement.id ? measurement : m)
        .toList();
  }

  Future<void> deleteMeasurement(String id) async {
    state = state.where((m) => m.id != id).toList();
  }
}

final measurementNotifierProvider =
    StateNotifierProvider<MeasurementNotifier, List<Measurement>>((ref) {
  return MeasurementNotifier();
});

class MeasurementFormNotifier extends StateNotifier<MeasurementFormState> {
  MeasurementFormNotifier() : super(const MeasurementFormState());

  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  void updateType(String type) {
    state = state.copyWith(type: type);
  }

  Future<bool> submit() async {
    if (state.name.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: 'El nombre es obligatorio',
        isSubmitting: false,
      );
      return false;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    await Future.delayed(const Duration(milliseconds: 500));

    state = const MeasurementFormState();
    return true;
  }

  void reset() {
    state = const MeasurementFormState();
  }
}

final measurementFormProvider =
    StateNotifierProvider<MeasurementFormNotifier, MeasurementFormState>((ref) {
  return MeasurementFormNotifier();
});
