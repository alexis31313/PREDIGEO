/// Enumeraciones de dominio para los atributos tipados de una medición.
///
/// Cada valor expone:
/// - [value]: identificador estable que se persiste en SQLite (y que coincide
///   con la restricción `CHECK` de la base de datos).
/// - [label]: etiqueta legible en español para la interfaz de usuario.
///
/// La capa de dominio no conoce detalles de SQLite: el parseo desde texto se
/// expone como utilidad de serialización y la capa de datos decide cómo
/// manejar un valor desconocido (ver `SqliteValues.fromEnum`).

/// Tipo de medición: polígono de área o trayecto recorrido.
enum MeasurementType {
  area('area', 'Área'),
  path('path', 'Trayecto');

  const MeasurementType(this.value, this.label);

  /// Identificador persistido en la columna `measurements.type`.
  final String value;

  /// Etiqueta en español para la interfaz.
  final String label;

  /// Convierte el valor persistido en la enumeración.
  /// Devuelve `null` si el valor no corresponde a ningún tipo válido.
  static MeasurementType? fromValue(String? value) {
    for (final type in MeasurementType.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

/// Modalidad de captura: con conexión (Google Maps) o completamente offline.
enum MeasurementMode {
  online('online', 'En línea'),
  offline('offline', 'Sin conexión');

  const MeasurementMode(this.value, this.label);

  /// Identificador persistido en la columna `measurements.mode`.
  final String value;

  /// Etiqueta en español para la interfaz.
  final String label;

  /// Convierte el valor persistido en la enumeración.
  /// Devuelve `null` si el valor no corresponde a ningún modo válido.
  static MeasurementMode? fromValue(String? value) {
    for (final mode in MeasurementMode.values) {
      if (mode.value == value) return mode;
    }
    return null;
  }
}

/// Categoría del terreno. Permite comparar la precisión del GNSS en los tres
/// escenarios de estudio: rural abierto, rural con vegetación y urbano.
enum MeasurementCategory {
  ruralOpen('rural_open', 'Rural abierto'),
  ruralVegetation('rural_vegetation', 'Rural con vegetación'),
  urban('urban', 'Urbano');

  const MeasurementCategory(this.value, this.label);

  /// Identificador persistido en la columna `measurements.category`.
  final String value;

  /// Etiqueta en español para la interfaz.
  final String label;

  /// Convierte el valor persistido en la enumeración.
  /// Devuelve `null` si el valor no corresponde a ninguna categoría válida
  /// (incluye el caso `NULL` de una medición sin categoría asignada).
  static MeasurementCategory? fromValue(String? value) {
    for (final category in MeasurementCategory.values) {
      if (category.value == value) return category;
    }
    return null;
  }
}

/// Magnitud contra la que se compara el resultado de la medición en la
/// evaluación de precisión de campo.
enum ReferenceType {
  area('area', 'Área (m²)'),
  distance('distance', 'Distancia (m)');

  const ReferenceType(this.value, this.label);

  /// Identificador persistido en la columna `field_evaluations.reference_type`.
  final String value;

  /// Etiqueta en español para la interfaz.
  final String label;

  /// Convierte el valor persistido en la enumeración.
  /// Devuelve `null` si el valor no corresponde a ningún tipo válido.
  static ReferenceType? fromValue(String? value) {
    for (final type in ReferenceType.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}