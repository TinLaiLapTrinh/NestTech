pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    // Đọc token Mapbox trực tiếp từ gradle.properties
    val mapboxToken: String = run {
        val properties = java.util.Properties()
        file("gradle.properties").inputStream().use { properties.load(it) }
        properties.getProperty("MAPBOX_DOWNLOADS_TOKEN") ?: ""
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
        maven {
            url = uri("https://api.mapbox.com/downloads/v2/releases/maven")
            credentials {
                username = "mapbox"
                password = "sk.eyJ1IjoidHJvbmd0aW4xMjkyMDA0IiwiYSI6ImNtZmYwY2xqNzA2MGwya3NlbnF3ZDlubTkifQ.Imtn6yqBOUlFprCVV77k6A"
            }
        }
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
        maven {
            url = uri("https://api.mapbox.com/downloads/v2/releases/maven")
            credentials {
                username = "mapbox"
                password = "sk.eyJ1IjoidHJvbmd0aW4xMjkyMDA0IiwiYSI6ImNtZmYwY2xqNzA2MGwya3NlbnF3ZDlubTkifQ.Imtn6yqBOUlFprCVV77k6A"
            }
        }
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.3" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")
