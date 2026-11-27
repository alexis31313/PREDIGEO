# Reglas de R8/ProGuard para la compilación release de PrediGeo.

# Flutter: el motor y los plugins se registran por reflexión.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Actividad principal (canales del barómetro).
-keep class com.digitallab.predigeo.MainActivity { *; }

# Play Core (componentes diferidos de Flutter que la app no usa).
-dontwarn com.google.android.play.core.**
