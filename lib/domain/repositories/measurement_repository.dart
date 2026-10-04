import '../entities/field_evaluation.dart';
import '../entities/measurement.dart';
import '../entities/measurement_enums.dart';

/// Contrato de persistencia de mediciones de PrediGeo.
///
/// La interfaz pertenece al dominio: no conoce SQLite ni ningún detalle de
/// almacenamiento, por lo que puede implementarse con distintos motores
/// (sqflite en el dispositivo, sqflite_common_ffi en pruebas) o ser simulada
/// con `mocktail`.
///
/// Semántica de carga de datos:
/// - [insertMeasurement] y [getById] devuelven la medición **con puntos y
///   evaluaciones** (lectura completa tras la escritura).
/// - [getAll], [search] y [filter] devuelven **solo la cabecera**, con las
///   listas `points` y `evaluations` vacías. Es la forma eficiente de alimentar
///   el historial, donde los puntos solo se necesitan al abrir el detalle.
///
/// Las operaciones que escriben más de una tabla son atómicas: o se guarda
/// todo (medición + puntos + evaluaciones) o no se guarda nada.
abstract interface class MeasurementRepository {
  /// Persiste una medición junto con sus puntos y evaluaciones en una única
  /// transacción atómica.
  ///
  /// El `seq` de cada punto se reasigna según la posición en la lista, y el
  /// `avgAccuracyM` se calcula a partir de los puntos cuando no se provee.
  /// Devuelve la medición persistida, ya con `id` asignado.
  Future<Measurement> insertMeasurement(Measurement measurement);

  /// Devuelve todas las mediciones ordenadas de más reciente a más antigua
  /// (`created_at DESC, id DESC`), sin puntos ni evaluaciones.
  Future<List<Measurement>> getAll();

  /// Devuelve una medición con sus puntos (ordenados por `seq`) y sus
  /// evaluaciones, o `null` si no existe una medición con ese `id`.
  Future<Measurement?> getById(int id);

  /// Actualiza la cabecera de una medición y reemplaza sus puntos y
  /// evaluaciones por los indicados, en una única transacción.
  /// Lanza `ValidationException` si la medición no tiene `id`.
  Future<Measurement> update(Measurement measurement);

  /// Elimina una medición. Los puntos y evaluaciones se borran en cascada.
  /// Si el `id` no existe, la operación no tiene efecto.
  Future<void> delete(int id);

  /// Elimina todas las mediciones (y, en cascada, sus puntos y evaluaciones).
  /// Devuelve la cantidad de mediciones eliminadas.
  Future<int> deleteAll();

  /// Busca mediciones cuyo nombre contiene [term], sin distinguir mayúsculas
  /// ni minúsculas. Un [term] vacío o nulo devuelve todas las mediciones.
  Future<List<Measurement>> search(String? term);

  /// Filtra mediciones por tipo, modalidad de captura y categoría de terreno.
  ///
  /// Los parámetros `null` se ignoran (no se filtran). Para seleccionar
  /// únicamente las mediciones sin categoría se debe usar [onlyUncategorized].
  Future<List<Measurement>> filter({
    MeasurementType? type,
    MeasurementMode? mode,
    MeasurementCategory? category,
    bool onlyUncategorized = false,
  });

  /// Devuelve la cantidad total de mediciones almacenadas.
  Future<int> count();

  /// Persiste una evaluación de campo asociada a una medición existente.
  Future<FieldEvaluation> insertEvaluation(FieldEvaluation evaluation);

  /// Devuelve las evaluaciones de campo de una medición, ordenadas por `id`.
  Future<List<FieldEvaluation>> getEvaluations(int measurementId);
}