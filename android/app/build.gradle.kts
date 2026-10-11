import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Lee MAPS_API_KEY desde android/local.properties (archivo no versionado).
// Si no existe, se usa una cadena vacía para no romper la compilación.
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.reader(Charsets.UTF_8).use { localProperties.load(it) }
}
val mapsApiKey: String = localProperties.getProperty("MAPS_API_KEY") ?: ""

android {
    namespace = "com.digitallab.predigeo"
    compileSdk = 34
    ndkVersion = "25.2.9519653"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8.toString()
    }

    defaultConfig {
        applicationId = "com.digitallab.predigeo"
        minSdk = 24
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
