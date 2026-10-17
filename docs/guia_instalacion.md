# Guía de Instalación — PrediGeo v1.0.0

## 1. Requisitos

| Requisito | Especificación |
|-----------|----------------|
| Sistema operativo | Android 7.0 (Nougat) / API 24 o superior |
| Espacio libre | 80 MB mínimo |
| Sensores | GPS/GNSS integrado |
| Conexión | No requerida (app 100 % offline) |

## 2. Permitir instalación desde fuentes desconocidas

Como el APK se distribuye fuera de Google Play:

1. Abre **Ajustes > Seguridad** (o **Ajustes > Apps > Acceso especial > Instalar apps desconocidas** en Android 8+).
2. Selecciona el navegador o el administrador de archivos que usarás.
3. Activa **Permitir desde esta fuente**.

## 3. Instalar el APK

1. Descarga `predigeo-v1.0.0.apk` desde la [GitHub Release v1.0.0](https://github.com/TU-USUARIO/predigeo/releases/tag/v1.0.0).
2. Abre el archivo descargado.
3. Confirma que el nombre del paquete sea `com.digitallab.predigeo`.
4. Pulsa **Instalar** y luego **Abrir**.
5. Verifica que el ícono (polígono tierra con punto GPS verde) y el nombre **PrediGeo** se vean en el lanzador.

## 4. Permisos que pide la app y por qué

| Permiso | Por qué se necesita |
|---------|---------------------|
| Ubicación precisa (`ACCESS_FINE_LOCATION`) | Capturar latitud, longitud y altitud de cada punto del terreno. Sin este permiso no se puede medir. |
| Ubicación aproximada (`ACCESS_COARSE_LOCATION`) | Respaldo cuando la señal fina aún no está disponible. |
| Internet (`INTERNET`) | Opcional: solo se usa para mostrar Google Maps en modo conectado. La medición funciona en modo avión. |
| Estado de red (`ACCESS_NETWORK_STATE`) | Detectar si hay conexión para elegir el modo de mapa. |

Los datos de tus terrenos **no salen del teléfono** en modo sin conexión: se guardan en SQLite local.

## 5. Generar el APK (desarrolladores)

```powershell
# APK universal firmado (release)
flutter build apk --release

# APK por arquitectura (más livianos)
flutter build apk --release --split-per-abi

# Opcional: App Bundle para Google Play
flutter build appbundle
```

Rutas de salida:

- Universal: `build/app/outputs/flutter-apk/app-release.apk`
- Por ABI: `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`, `app-arm64-v8a-release.apk`, `app-x86_64-release.apk`
- Bundle: `build/app/outputs/bundle/release/app-release.aab`

### SHA-256 del APK

```powershell
# Windows (PowerShell)
Get-FileHash build/app/outputs/flutter-apk/app-release.apk -Algorithm SHA256

# Linux / macOS
sha256sum build/app/outputs/flutter-apk/app-release.apk
```

Publica el hash junto al APK para que cualquiera verifique la descarga.

## 6. Huella SHA-1 del keystore y restricción de la API key

Obtén la huella del certificado de firma:

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -list -v `
  -keystore android/predigeo-release.jks -alias predigeo
```

Copia el valor `SHA1`. En [Google Cloud Console](https://console.cloud.google.com/):

1. Ve a **APIs y servicios > Credenciales**.
2. Abre tu API key de Maps.
3. En **Restricciones de aplicaciones**, elige **Aplicaciones Android**.
4. Agrega una entrada con:
   - Nombre del paquete: `com.digitallab.predigeo`
   - Huella SHA-1: la obtenida con keytool.
5. Guarda los cambios.

## 7. Solución de problemas

| Síntoma | Causa probable | Solución |
|---------|----------------|----------|
| "No se pudo instalar" | Fuentes desconocidas bloqueadas | Activa el permiso del paso 2 |
| Pide actualizar y no instala | Firma distinta a la versión instalada | Desinstala la versión anterior o firma con el mismo keystore |
| No hay señal GPS | GPS apagado o interiores | Activa ubicación en modo alta precisión y sal al exterior |
| El mapa no carga | Sin Internet o API key sin restringir bien | Funciona igual offline; revisa la restricción del paso 6 |
