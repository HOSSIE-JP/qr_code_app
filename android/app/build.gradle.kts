import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties().apply {
    val localPropertiesFile = rootProject.file("local.properties")
    if (localPropertiesFile.exists()) {
        FileInputStream(localPropertiesFile).use(::load)
    }
}

val signingProperties = Properties()
val signingPropertiesPath = localProperties.getProperty("priqr.signing.properties")
val signingPropertiesFile = signingPropertiesPath?.let(::file)
val hasReleaseSigning = signingPropertiesFile?.isFile == true

if (hasReleaseSigning) {
    FileInputStream(signingPropertiesFile!!).use(signingProperties::load)
} else {
    logger.warn(
        "Release signing is not configured. Set priqr.signing.properties in android/local.properties to build a signed release.",
    )
}

android {
    namespace = "jp.co.geroneko"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    packaging {
        resources {
            excludes += "META-INF/DEPENDENCIES"
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                val storeFilePath = signingProperties.getProperty("storeFile")
                    ?: error("storeFile is missing in signing properties.")
                storeFile = file(storeFilePath)
                storePassword = signingProperties.getProperty("storePassword")
                    ?: error("storePassword is missing in signing properties.")
                keyAlias = signingProperties.getProperty("keyAlias")
                    ?: error("keyAlias is missing in signing properties.")
                keyPassword = signingProperties.getProperty("keyPassword")
                    ?: error("keyPassword is missing in signing properties.")
            }
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "jp.co.geroneko"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["msalRedirectHost"] = "jp.co.geroneko"
        manifestPlaceholders["msalRedirectPath"] = "/zzvXMUAcU3YjMd0QbTOeRb7g8dY="
    }

    buildTypes {
        release {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

flutter {
    source = "../.."
}
