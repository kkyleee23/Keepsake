import java.io.FileInputStream
import java.util.Properties

// Real signing details, when this machine has them. android/key.properties is
// never committed, so a checkout without it still builds: it falls back to the
// debug key, which is fine for trying the app but not for publishing.
val keystoreFile = rootProject.file("key.properties")
val keystore = Properties().apply {
    if (keystoreFile.exists()) FileInputStream(keystoreFile).use { load(it) }
}
val hasKeystore = keystoreFile.exists()

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.keepsake.keepsake"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.keepsake.keepsake"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasKeystore) {
                storeFile = file(keystore.getProperty("storeFile"))
                storePassword = keystore.getProperty("storePassword")
                keyAlias = keystore.getProperty("keyAlias")
                keyPassword = keystore.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Signed properly when android/key.properties is here. Without it
            // the debug key is used so the build still runs, and the message
            // below says what that means.
            signingConfig = if (hasKeystore) {
                signingConfigs.getByName("release")
            } else {
                logger.warn(
                    "Keepsake: no android/key.properties, so this release is " +
                        "signed with the debug key. Fine for installing by hand, " +
                        "not for Google Play. See docs/SETUP.md.",
                )
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
