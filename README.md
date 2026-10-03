# PrediGeo

Aplicación móvil Flutter para la captura, procesamiento y análisis de datos GPS en tiempo real, orientada a la medición de áreas, distancias y perímetros de terrenos.

## Descripción del Proyecto

PrediGeo es una herramienta de medición geográfica que permite a los usuarios capturar coordenadas GPS, calcular áreas y perímetros de terrenos, visualizar perfiles de elevación y exportar datos. La aplicación opera en modo offline-first, garantizando funcionalidad completa sin conexión a internet.

## Características Principales

- Captura de coordenadas GPS (latitud, longitud, altitud)
- Cálculo de área por fórmula de Gauss (shoelace)
- Cálculo de distancia y perímetro con fórmula de Haversine
- Filtrado de señal GPS con filtro de Kalman
- Almacenamiento local en SQLite
- Historial de mediciones con consulta y gestión
- Visualización de perfil de elevación
- Evaluación de precisión (error absoluto, porcentual, RMSE)
- Modo conectado con Google Maps
- Modo offline sin dependencia de internet
- Exportación de datos en formato CSV
- Gestión de permisos de ubicación

## Stack Tecnológico

- **Framework**: Flutter 3.x
- **Lenguaje**: Dart
- **Gestión de Estado**: Riverpod
- **Navegación**: go_router
- **Base de Datos**: SQLite (sqflite)
- **Mapas**: google_maps_flutter
- **Geolocalización**: geolocator
- **Gráficas**: fl_chart
- **Exportación**: csv

## Instalación

### Prerrequisitos

- Flutter SDK 3.x o superior
- Dart SDK 3.x o superior
- Android Studio o VS Code con extensiones de Flutter
- Dispositivo Android 7.0+ o emulador

### Pasos

1. Clonar el repositorio:

```bash
git clone https://github.com/tu-usuario/predigeo.git
cd predigeo
```

2. Instalar dependencias:

```bash
flutter pub get
```

3. Configurar la API key de Google Maps:

   - Crear un proyecto en [Google Cloud Console](https://console.cloud.google.com/)
   - Habilitar la API de Maps SDK for Android
   - Generar una clave de API
   - Agregar la clave en `android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="TU_API_KEY_AQUI"/>
```

4. Configurar permisos de ubicación en `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

## Cómo Ejecutar

```bash
flutter run
```

Para generar un APK de release:

```bash
flutter build apk --release
```

## Estructura del Proyecto

```
predigeo/
├── android/
├── ios/
├── lib/
│   ├── main.dart
│   ├── app_theme.dart
│   ├── router.dart
│   ├── core/
│   │   ├── constants/
│   │   ├── utils/
│   │   └── errors/
│   ├── data/
│   │   ├── datasources/
│   │   ├── models/
│   │   └── repositories/
│   ├── domain/
│   │   ├── entities/
│   │   ├── repositories/
│   │   └── usecases/
│   └── presentation/
│       ├── providers/
│       ├── screens/
│       └── widgets/
├── docs/
│   ├── requisitos.md
│   └── arquitectura.md
├── test/
├── pubspec.yaml
└── README.md
```

## Equipo

- **Steve Alexander Calvache Martinez**
- **Luis Alejandro Paz Acero**

## Institución

Tecnología en Desarrollo de Software
Mocoa, Putumayo

## Licencia

Este proyecto está bajo la Licencia MIT. Consulta el archivo [LICENSE](LICENSE) para más detalles.
