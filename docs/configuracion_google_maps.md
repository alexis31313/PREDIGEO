# Configuración de Google Maps — PrediGeo

Este documento explica cómo habilitar el **modo conectado** de PrediGeo, que
muestra las mediciones sobre un mapa de Google Maps. El modo conectado es
opcional: sin conexión, la aplicación usa la vista de relieve local y sigue
funcionando con normalidad (offline-first).

## 1. Requisitos

- Una cuenta de Google Cloud.
- Una clave de API habilitada para **Maps SDK for Android**.

## 2. Obtener la clave de API

1. Entre a <https://console.cloud.google.com/>.
2. Cree (o seleccione) un proyecto.
3. Habilite **Maps SDK for Android** en *APIs y servicios → Biblioteca*.
4. En *APIs y servicios → Credenciales*, cree una **Clave de API**.
5. Restrinja la clave a la aplicación Android:
   - **Nombre del paquete:** `com.digitallab.predigeo`
   - **Huella SHA-1** de la clave de firma (debug o release).

## 3. Configurar la clave en el proyecto

La clave **no** se versiona. Se lee desde `android/local.properties`, un archivo
ignorado por Git.

1. Copie el archivo de ejemplo:

   ```powershell
   Copy-Item android\local.properties.example android\local.properties
   ```

2. Edite `android/local.properties` y complete `MAPS_API_KEY`:

   ```properties
   sdk.dir=C\:\\Users\\YourUser\\AppData\\Local\\Android\\Sdk
   flutter.sdk=C\:\\src\\flutter
   MAPS_API_KEY=TU_CLAVE_DE_API
   ```

3. `android/app/build.gradle.kts` inyecta el valor en el manifiesto mediante un
   `manifestPlaceholders`:

   ```kotlin
   manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
   ```

   Y `android/app/src/main/AndroidManifest.xml` lo consume:

   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="${MAPS_API_KEY}" />
   ```

## 4. Compilar y ejecutar

```powershell
flutter pub get
flutter run
```

Si la clave falta o es inválida, el mapa se mostrará en blanco, pero la
aplicación seguirá funcionando en modo offline.

## 5. Alternancia automática de modo

La aplicación detecta la conectividad con `connectivity_plus`:

- **Con conexión:** la sección "Mapa / relieve" de la pantalla de medición
  muestra el mapa de Google Maps (polígono, marcadores por vértice y cámara
  centrada en el área).
- **Sin conexión:** se muestra la vista de relieve local y el banner
  "Modo Sin Conexión".

La preferencia **normal/satelital** del mapa se guarda en el dispositivo con
`shared_preferences` y se conserva entre sesiones.

## 6. Seguridad

- Nunca suba `android/local.properties` al repositorio (ya está en
  `.gitignore`).
- Restrinja la clave de API por nombre de paquete y huella SHA-1.
- No incluya la clave en capturas de pantalla ni en la documentación.
