// Exportación de la evaluación de precisión a un archivo CSV.
//
// El archivo se guarda en el directorio de documentos de la aplicación con
// un nombre que incluye la marca de tiempo para no sobrescribir informes
// anteriores.

import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'precision_analyzer.dart';

/// Exporta el informe de evaluación de precisión a CSV.
class EvaluationExport {
  const EvaluationExport();

  /// Genera un archivo CSV con los pares evaluados y devuelve su ruta.
  ///
  /// Encabezados: categoria, modo, valor_medido, valor_referencia,
  /// error_absoluto, error_porcentual. Los valores numéricos usan punto
  /// decimal y 4 decimales para facilitar el análisis en hojas de cálculo.
  Future<String> exportToCSV(EvaluationReport report) async {
    final buffer = StringBuffer()
      ..writeln('categoria,modo,valor_medido,valor_referencia,'
          'error_absoluto,error_porcentual');

    for (final pair in report.pairs) {
      buffer.writeln(<String>[
        _escapeCsvField(pair.category.label),
        _escapeCsvField(pair.mode.label),
        pair.measuredValue.toStringAsFixed(4),
        pair.referenceValue.toStringAsFixed(4),
        pair.absoluteError.toStringAsFixed(4),
        pair.percentError.toStringAsFixed(4),
      ].join(','));
    }

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/evaluacion_$timestamp.csv');
    await file.writeAsString(buffer.toString());
    return file.path;
  }

  /// Encierra el campo entre comillas cuando contiene coma, comillas o saltos
  /// de línea, y duplica las comillas internas.
  String _escapeCsvField(String value) {
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
