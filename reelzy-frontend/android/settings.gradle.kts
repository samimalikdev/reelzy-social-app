pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"

    // UPDATED AGP VERSION → required by androidx.activity 1.11.0
    id("com.android.application") version "8.9.1" apply false

    // FlutterFire
    id("com.google.gms.google-services") version("4.3.15") apply false

    // UPDATED KOTLIN VERSION → Flutter requires 2.1.0+
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")
