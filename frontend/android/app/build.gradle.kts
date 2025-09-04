plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin") // flutter plugin luôn đặt cuối
    id("com.google.gms.google-services")    
}

android {
    namespace = "com.example.frontend"
        compileSdk = 35  


    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
<<<<<<< HEAD
        applicationId = "com.vtt.technet"
        // minSdk = flutter.minSdkVersion
        targetSdk = 35 
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        minSdk = 21 
        multiDexEnabled = true
=======
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.frontend"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
>>>>>>> 362a5ce8c9896e7b0e02934d38d47ce065d37035
    }

    buildTypes {
        release {
<<<<<<< HEAD
=======
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
>>>>>>> 362a5ce8c9896e7b0e02934d38d47ce065d37035
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
<<<<<<< HEAD

// 🔥 dependencies phải để ngoài android block
dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.1.2"))
    implementation("com.google.firebase:firebase-messaging")
    implementation("com.google.firebase:firebase-analytics")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

// 🔥 plugin google-services phải để cuối cùng
apply(plugin = "com.google.gms.google-services")
=======
>>>>>>> 362a5ce8c9896e7b0e02934d38d47ce065d37035
