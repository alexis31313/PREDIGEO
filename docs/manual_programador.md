# Manual de Programador - PrediGeo

## Documentación Técnica para Desarrolladores

---

## Índice

1. [Arquitectura General](#1-arquitectura-general)
2. [Estructura del Proyecto](#2-estructura-del-proyecto)
3. [Compilación y Ejecución](#3-compilación-y-ejecución)
4. [Ejecución de Pruebas](#4-ejecución-de-pruebas)
5. [Dependencias](#5-dependencias)
6. [Convenciones de Código](#6-convenciones-de-código)
7. [Esquema de Base de Datos](#7-esquema-de-base-de-datos)
8. [Guía de Contribución](#8-guía-de-contribución)

---

## 1. Arquitectura General

PrediGeo implementa el patrón de **Arquitectura Limpia (Clean Architecture)** con tres capas principales:

```
┌─────────────────────────────────────────────────────┐
│               PRESENTATION LAYER                    │
│   (Widgets, Screens, Providers, Router)            │
├─────────────────────────────────────────────────────┤
│                  DOMAIN LAYER                       │
│   (Entities, UseCases, Repositories Interfaces)    │
├─────────────────────────────────────────────────────┤
│                   DATA LAYER                        │
│   (Models, DataSources, Repository Impl, DB)      │
└─────────────────────────────────────────────────────┘
```

### Principios

- **Independencia:** La capa de dominio no depende de Flutter ni de SQLite.
- **Inversión de dependencias:** Las interfaces de repositorio se definen en dominio y se implementan en datos.
- **Testabilidad:** La separación en capas facilita pruebas unitarias y de integración.

---

## 2. Estructura del Proyecto

```
predigeo/
├── lib/
│   ├── core/                          # Utilidades y configuración global
│   │   ├── constants/
│   │   │   └── app_constants.dart     # Constantes (nombres tablas, columnas, etc.)
│   │   ├── errors/
│   │   │   ├── exceptions.dart        # Excepciones personalizadas
│   │   │   └── failures.dart          # Fallos de dominio
│   │   ├── theme/
│   │   │   └── app_theme.dart         # Tema Material 3
│   │   └── utils/
│   │       ├── validators.dart        # Validadores de entrada
│   │       ├── geo_utils.dart        # Utilidades geoespaciales
│   │       └── formatters.dart       # Formateadores de valores
│   │
│   ├── data/                          # Capa de datos
│   │   ├── datasources/
│   │   │   ├── database_helper.dart  # Inicialización y gestión de SQLite
│   │   │   ├── location_service.dart # Servicio de ubicación del dispositivo
│   │   │   ├── local/
│   │   │   │   └── location_datasource.dart
│   │   │   └── remote/
│   │   │       └── connectivity_datasource.dart
│   │   ├── export/
│   │   │   ├── export_service.dart   # Generación de archivos CSV
│   │   │   └── export_exception.dart # Errores de exportación
│   │   ├── models/
│   │   │   ├── measurement_model.dart
│   │   │   ├── geo_point_model.dart
│   │   │   ├── field_evaluation_model.dart
│   │   │   └── sqlite_values.dart    # Mapeo enum ↔ SQLite
│   │   └── repositories/
│   │       └── sqlite_measurement_repository.dart
│   │
│   ├── domain/                        # Capa de dominio
│   │   ├── entities/
│   │   │   ├── geo_point.dart
│   │   │   ├── measurement.dart
│   │   │   ├── gps_reading.dart
│   │   │   ├── location_status.dart
│   │   │   ├── field_evaluation.dart
│   │   │   └── measurement_enums.dart
│   │   ├── repositories/
│   │   │   └── measurement_repository.dart  # Interfaz abstracta
│   │   └── usecases/
│   │       ├── calculate_area_usecase.dart
│   │       ├── calculate_distance_usecase.dart
│   │       ├── evaluate_accuracy_usecase.dart
│   │       ├── export_measurements_usecase.dart
│   │       ├── filter_coordinates_usecase.dart
│   │       ├── get_measurements_usecase.dart
│   │       ├── save_measurement_usecase.dart
│   │       ├── delete_measurement_usecase.dart
│   │       ├── evaluation/
│   │       │   └── precision_analyzer.dart
│   │       ├── geo/
│   │       │   ├── area_calculator.dart
│   │       │   ├── area_units.dart
│   │       │   ├── geo_projector.dart
│   │       │   ├── point2d.dart
│   │       │   └── polygon_validator.dart
│   │       └── signal_processing/
│   │           ├── point_capture_service.dart
│   │           ├── simple_kalman_filter.dart
│   │           ├── weighted_averager.dart
│   │           ├── outlier_filter.dart
│   │           └── captured_point.dart
│   │
│   ├── presentation/                  # Capa de presentación
│   │   ├── providers/
│   │   │   ├── measurement_provider.dart
│   │   │   ├── measurement_repository_provider.dart
│   │   │   ├── gps_provider.dart
│   │   │   ├── gps_state_notifier.dart
│   │   │   ├── connectivity_provider.dart
│   │   │   └── filter_provider.dart
│   │   ├── router/
│   │   │   └── app_router.dart
│   │   ├── screens/
│   │   │   ├── home_screen.dart
│   │   │   ├── measure_screen.dart
│   │   │   ├── history_screen.dart
│   │   │   ├── measurement_detail_screen.dart
│   │   │   └── evaluation_screen.dart
│   │   └── widgets/
│   │       ├── measurement_card.dart
│   │       ├── elevation_profile_chart.dart
│   │       ├── terrain_relief_view.dart
│   │       ├── signal_indicator.dart
│   │       ├── gps_status_indicator.dart
│   │       └── offline_banner.dart
│   │
│   └── main.dart                      # Punto de entrada
│
├── test/                              # Pruebas unitarias y de widgets
├── assets/                            # Recursos estáticos
├── android/                           # Configuración Android
├── pubspec.yaml                       # Dependencias y metadatos
└── analysis_options.yaml              # Reglas de lint
```

---

## 3. Compilación y Ejecución

### Requisitos Previos

1. **Flutter SDK:** Versión 3.x o superior.
2. **Android Studio** o **VS Code** con la extensión de Flutter.
3. **JDK 11** o superior.
4. **Android SDK** con API Level 24+ (Android 7.0+).
5. **Emulador Android** o dispositivo físico.

### Comandos de Compilación

```bash
# Instalar dependencias
flutter pub get

# Ejecutar en modo debug (emulador o dispositivo)
flutter run

# Ejecutar en modo release
flutter run --release

# Compilar APK debug
flutter build apk --debug

# Compilar APK release
flutter build apk --release

# Compilar para distribución
flutter build apk --split-per-abi
```

### Configuración Android

Archivo clave: `android/app/build.gradle`

```groovy
android {
    defaultConfig {
        minSdk = 24          // Android 7.0 Nougat
        targetSdk = 34       // Android 14
        versionCode = 1
        versionName = "1.0.0"
    }
}
```

Permisos requeridos en `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

---

## 4. Ejecución de Pruebas

### Ejecutar Todas las Pruebas

```bash
flutter test
```

### Ejecutar un Archivo Específico de Pruebas

```bash
flutter test test/evaluation/precision_analyzer_test.dart
```

### Ejecutar con Cobertura

```bash
flutter test --coverage
```

### Ver Informe de Cobertura

```bash
genhtml coverage/lcov.info -o coverage/html
start coverage/html/index.html
```

---

## 5. Dependencias

### Dependencias de Producción

| Paquete | Versión | Uso |
|---------|---------|-----|
| `flutter` | SDK | Framework principal |
| `flutter_localizations` | SDK | Localización (español) |
| `sqflite` | ^2.3.0 | Base de datos SQLite local |
| `path_provider` | ^2.1.0 | Rutas del sistema de archivos |
| `path` | ^1.8.0 | Manipulación de rutas |
| `geolocator` | ^13.0.0 | Acceso al GPS del dispositivo |
| `connectivity_plus` | ^6.0.0 | Detección de estado de red |
| `intl` | ^0.19.0 | Formato de fechas y números |
| `provider` | ^6.1.0 | Gestión de estado |
| `go_router` | ^14.0.0 | Navegación declarativa |
| `share_plus` | ^10.0.0 | Compartir archivos exportados |
| `fl_chart` | ^0.69.0 | Gráficos (perfil de elevación) |

### Dependencias de Desarrollo

| Paquete | Versión | Uso |
|---------|---------|-----|
| `flutter_test` | SDK | Framework de pruebas |
| `flutter_lints` | ^5.0.0 | Reglas de lint recomendadas |
| `mockito` | ^5.4.0 | Mocks para pruebas |
| `build_runner` | ^2.4.0 | Generación de código |

---

## 6. Convenciones de Código

### Nomenclatura

| Elemento | Convención | Ejemplo |
|----------|------------|---------|
| Clases | PascalCase | `MeasurementRepository` |
| Métodos/Variables | camelCase | `calculateArea()` |
| Constantes | camelCase | `defaultGpsAccuracy` |
| Archivos | snake_case | `precision_analyzer.dart` |
| Enumeraciones | PascalCase (tipo) | `MeasurementCategory` |
| Enum values | lowerCamelCase | `ruralOpen` |

### Documentación

- Todos los miembros públicos requieren comentarios `///` en español.
- Formato de documentación:
  ```dart
  /// Descripción breve del elemento.
  ///
  /// Descripción detallada si es necesario.
  /// 
  /// Parámetros:
  /// - [param]: descripción.
  ///
  /// Devuelve: descripción del valor de retorno.
  ```

### Estructura de Casos de Uso

```dart
/// Descripción del caso de uso.
class NombreUsecase {
  static const double _constantePrivada = valor;

  /// Descripción del método principal.
  TipoRetorno call(TipoParametro parametro) {
    // Implementación
  }

  /// Método privado de apoyo.
  Tipo _metodoPrivado() {
    // Implementación
  }
}
```

### Estructura de Entidades

```dart
/// Entidad de dominio que representa...
class NombreEntidad {
  const NombreEntidad({
    required this.atributo,
  });

  final Tipo atributo;
}
```

### Manejo de Errores

- Usar `Exception` para errores recuperables.
- Usar `Failure` para errores de dominio.
- Registrar errores en consola solo en modo debug.

### Gestión de Estado

- Usar `Provider` + `ChangeNotifier` para estado simple.
- Mantener los `Provider` lo más cerca posible al widget que los consume.
- No mezclar lógica de presentación con lógica de dominio.

---

## 7. Esquema de Base de Datos

### Versión Actual: v2

```sql
-- Tabla principal de mediciones
CREATE TABLE measurements (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    name            TEXT    NOT NULL,
    type            TEXT    NOT NULL CHECK(type IN ('area', 'path')),
    area_m2         REAL    NOT NULL DEFAULT 0,
    perimeter_m     REAL    NOT NULL DEFAULT 0,
    distance_m      REAL    NOT NULL DEFAULT 0,
    mode            TEXT    NOT NULL CHECK(mode IN ('online', 'offline')),
    category        TEXT    CHECK(category IN ('rural_open', 'rural_vegetation', 'urban')),
    notes           TEXT,
    avg_accuracy_m  REAL    NOT NULL DEFAULT 0,
    created_at      TEXT    NOT NULL  -- ISO8601 UTC
);

-- Puntos capturados por cada medición
CREATE TABLE measurement_points (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    measurement_id  INTEGER NOT NULL,
    seq             INTEGER NOT NULL,
    latitude        REAL    NOT NULL,
    longitude       REAL    NOT NULL,
    altitude        REAL,
    accuracy        REAL    NOT NULL,
    timestamp       TEXT    NOT NULL,
    FOREIGN KEY (measurement_id) REFERENCES measurements(id) ON DELETE CASCADE,
    UNIQUE (measurement_id, seq)
);

-- Evaluaciones de campo (comparación con referencias)
CREATE TABLE field_evaluations (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    measurement_id  INTEGER NOT NULL,
    reference_value REAL    NOT NULL,
    reference_source TEXT,
    reference_type  TEXT    NOT NULL CHECK(reference_type IN ('area', 'distance')),
    env_conditions  TEXT,
    created_at      TEXT    NOT NULL,
    FOREIGN KEY (measurement_id) REFERENCES measurements(id) ON DELETE CASCADE
);

-- Índices
CREATE INDEX idx_measurements_created_at ON measurements(created_at DESC);
CREATE INDEX idx_measurement_points_measurement_seq ON measurement_points(measurement_id, seq);
CREATE INDEX idx_field_evaluations_measurement_id ON field_evaluations(measurement_id);
```

### Migración v1 → v2

El `DatabaseHelper` detecta automáticamente la versión y realiza la migración conservando los datos existentes.

---

## 8. Guía de Contribución

### Configuración del Entorno

```bash
# Clonar el repositorio
git clone [url-del-repositorio]

# Instalar dependencias
flutter pub get

# Crear rama para la nueva funcionalidad
git checkout -b feature/nombre-descriptivo
```

### Flujo de Trabajo

1. **Crear una rama** desde `main` con el prefijo:
   - `feature/` para nuevas funcionalidades
   - `fix/` para corrección de errores
   - `docs/` para documentación
   - `refactor/` para refactorización

2. **Implementar** los cambios siguiendo las convenciones del proyecto.

3. **Ejecutar pruebas** antes de enviar:
   ```bash
   flutter analyze
   flutter test
   ```

4. **Realizar commit** con mensaje descriptivo:
   ```
   feat: agregar filtro por categoría en historial
   
   - Se añadió el widget FilterChips
   - Se actualizó HistoryProvider
   - Se incluyeron pruebas unitarias
   ```

5. **Enviar Pull Request** con:
   - Título descriptivo
   - Descripción de los cambios
   - Referencia al issue aplica

### Estándares de Código

- Seguir las reglas de `flutter_lints`.
- Toda la documentación en español.
- Cobertura mínima del 80% para nuevos casos de uso.
- No incluir dependencias sin aprobación previa.

### Reporte de Errores

Al reportar un error incluir:
1. Versión de Flutter (`flutter --version`)
2. Versión de la aplicación
3. Pasos para reproducir el error
4. Comportamiento esperado vs. obtenido
5. Capturas de pantalla si aplica
6. Logs del dispositivo (`flutter run --verbose`)

---

*PrediGeo - Universidad de Putumayo*  
*Última actualización: Octubre 2026*
