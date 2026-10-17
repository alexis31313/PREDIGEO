# PrediGeo

[![Descargar APK v1.0.0](https://img.shields.io/badge/Descargar-APK%20v1.0.0-2E7D32?style=for-the-badge&logo=android)](https://github.com/TU-USUARIO/predigeo/releases/tag/v1.0.0)

Aplicación móvil Flutter para la captura, procesamiento y análisis de datos GPS en tiempo real, orientada a la medición de áreas, distancias y perímetros de terrenos.

> **Instalación rápida:** descarga `predigeo-v1.0.0.apk` desde la [Release v1.0.0](https://github.com/TU-USUARIO/predigeo/releases/tag/v1.0.0) y sigue la [guía de instalación](docs/guia_instalacion.md). Requiere Android 7.0 (API 24) o superior.

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
- Exportación de datos en formatos CSV, GeoJSON y KML
- Gestión de permisos de ubicación

## Capturas de Pantalla

[Captura pendiente]

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

3. Configurar la API key de Google Maps en `local.properties`:

```properties
googleMapsApiKey=TU_API_KEY_AQUI
```

4. Configurar permisos de ubicación en `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

## Uso

### Ejecutar la aplicación

```bash
flutter run
```

### Ejecutar pruebas

```bash
flutter test
```

### Generar APK de depuración

```bash
flutter build apk --debug
```

### Generar APK firmado (release)

```bash
flutter build apk --release
flutter build apk --release --split-per-abi
# Opcional para Google Play:
flutter build appbundle
```

El APK queda en `build/app/outputs/flutter-apk/app-release.apk`. Verifica su integridad con:

```powershell
Get-FileHash build/app/outputs/flutter-apk/app-release.apk -Algorithm SHA256
```

Ver la [guía de instalación](docs/guia_instalacion.md) para requisitos, permisos y firma.

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
- **Asesor**: Jhon Alexander Gómez

## Institución

Tecnología en Desarrollo de Software
Mocoa, Putumayo

## Licencia

Este proyecto está bajo la Licencia MIT. Su uso con fines académicos es libre y bienvenido, solicitando únicamente la atribución correspondiente a los autores. Consulta el archivo [LICENSE](LICENSE) para más detalles.
