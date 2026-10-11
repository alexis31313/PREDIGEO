import 'package:csv/csv.dart';

import '../entities/measurement.dart';
import '../repositories/measurement_repository.dart';

/// Caso de uso que exporta el historial de mediciones a un CSV en memoria.
///
/// La generación del archivo (y su posterior compartir con otras aplicaciones)
/// corresponde a la capa de presentación; este caso de uso solo arma el
/// contenido tabular desde los datos locales, de modo que funciona también en
/// pruebas sin depender del sistema de archivos.
class ExportMeasurementsUsecase {
  final MeasurementRepository _repository;

  const ExportMeasurementsUsecase(this._repository);

  /// Devuelve el contenido CSV del historial completo.
  Future<String> call() async {
    final measurements = await _repository.getAll();

    final rows = <List<dynamic>>[
      <dynamic>[
        'id',
        'name',
        'type',
        'area_m2',
        'perimeter_m',
        'distance_m',
        'mode',
        'category',
        'avg_accuracy_m',
        'point_count',
        'created_at',
        'notes',
      ],
    ];

    for (final measurement in measurements) {
      rows.add(_toRow(measurement));
    }

    return const ListToCsvConverter().convert(rows);
  }

  List<dynamic> _toRow(Measurement measurement) {
    return <dynamic>[
      measurement.id ?? '',
      measurement.name,
      measurement.type.value,
      measurement.areaM2 ?? '',
      measurement.perimeterM ?? '',
      measurement.distanceM ?? '',
      measurement.mode.value,
      measurement.category?.value ?? '',
      measurement.avgAccuracyM ?? '',
      measurement.pointCount,
      measurement.createdAt.toIso8601String(),
      measurement.notes ?? '',
    ];
  }
}
