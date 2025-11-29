plugins {
    id("com.android.application")
    id("kotlin-android")
    // Le plugin Flutter doit être appliqué après Android et Kotlin
    id("dev.flutter.flutter-gradle-plugin")
    // ✅ Ajout pour Firebase / Google Services
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.klivjna_rebuild"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true // ✅ syntaxe Kotlin DSL correcte
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString() // ✅ cohérent avec Java 17
    }

    defaultConfig {
        applicationId = "com.example.klivjna_rebuild"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {
            // ⚠️ À remplacer par un vrai keystore pour publication sur Play Store
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ nécessaire pour flutter_local_notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")

    // ✅ Import du BoM Firebase (gère les versions automatiquement)
    implementation(platform("com.google.firebase:firebase-bom:34.6.0"))

    // ✅ Ajout Firebase Analytics (optionnel mais recommandé)
    implementation("com.google.firebase:firebase-analytics")

    // ✅ Ajout Firebase Messaging pour notifications push
    implementation("com.google.firebase:firebase-messaging")
}
