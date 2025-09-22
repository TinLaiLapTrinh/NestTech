plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services") 
    id("dev.flutter.flutter-gradle-plugin") 
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
        applicationId = "com.vtt.technet"
        // minSdk = flutter.minSdkVersion
        targetSdk = 35 
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        minSdk = 23 
        multiDexEnabled = true
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


dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.1.2"))
    implementation("com.google.firebase:firebase-messaging")
    implementation("com.google.firebase:firebase-analytics")
    
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}


apply(plugin = "com.google.gms.google-services")
