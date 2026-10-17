# Reglas ProGuard/R8 para PrediGeo (release con minifyEnabled).
# Flutter ya incluye sus reglas base; aquí solo se conservan las clases
# que usan reflexión en los plugins (geolocator, sqflite, path_provider,
# share_plus, google_maps_flutter).

-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class com.google.android.gms.maps.** { *; }
-keep class com.google.maps.** { *; }
