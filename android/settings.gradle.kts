pluginManagement {
    val flutterSdkPath = run {
        val props = java.util.Properties()
        file("local.properties").inputStream().use { props.load(it) }
        val path = props.getProperty("flutter.sdk")
        require(path != null) { "flutter.sdk not set in local.properties" }
        path
    }

    // Let Flutter manage its Gradle integration
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    // Flutter loader
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"

    // Android Gradle Plugin (match your Flutter toolchain)
    id("com.android.application") version "8.9.1" apply false

    // Kotlin (use the version Flutter supports broadly)
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    id("com.google.gms.google-services") version "4.3.15" apply false
}

// Flutter module
include(":app")
