plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Google services plugin (Firebase)
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.nutricare_mvp"
    // Use explicit SDK levels to ensure compatibility with Firebase and modern Android emulators
    // Device logs earlier referenced SDK 36 — use 36 to match modern emulators and Play services
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.nutricare_mvp"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Set stable minimum/target SDKs for emulator testing and Firebase compatibility
        minSdk = flutter.minSdkVersion
        // Match the compileSdk with targetSdk to avoid runtime warnings on modern devices/emulators
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Enable MultiDex in case dependencies require >64K methods on devices
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
}
