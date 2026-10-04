/// Conversión de valores entre SQLite y el dominio.
/// Reglas aplicadas por la capa de datos:
/// - Las marcas de tiempo se persisten como texto ISO8601 **en UTC**, de modo
///   que el orden lexicográfico coincida con el orden cronológico real
///   (`created_at DESC` ordena correctamente aunque cambie la zona horaria).
/// - Los `NULL` de SQLite se traducen a `null` del dominio y viceversa.
class SqliteValues {
  SqliteValues._();

  /// Serializa una fecha como ISO8601 UTC.
  static String dateTimeToText(DateTime value) =>
      value.toUtc().toIso8601String();

  /// Lee una fecha desde SQLite.
  ///
  /// Acepta el formato ISO8601 (v2 y v1 migrada) y, por robustez, también
  /// valores numéricos epoch en milisegundos. El resultado se devuelve en hora
  /// local. Lanza [ArgumentError] si el valor es `null` o no es interpretable.
  static DateTime dateTimeFromText(
    Object? raw, {
    String column = 'created_at',
  }) {
    if (raw == null) {
      throw ArgumentError('La columna "$column" no puede ser nula.');
    }
    if (raw is num) {
      return DateTime.fromMillisecondsSinceEpoch(raw.toInt()).toLocal();
    }
    final text = raw.toString();
    final parsed = DateTime.tryParse(text);
    if (parsed == null) {
      throw ArgumentError('El valor "$text" de "$column" no es una fecha válida.');
    }
    return parsed.toLocal();
  }

  /// Convierte un valor numérico de SQLite a `double?`.
  static double? toDouble(Object? raw) =>
      raw == null ? null : (raw as num).toDouble();

  /// Convierte un valor numérico de SQLite a `int?`.
  static int? toInt(Object? raw) => raw == null ? null : (raw as num).toInt();

  /// Convierte un valor de SQLite a `String?`.
  static String? toStringOrNull(Object? raw) => raw?.toString();
}