import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

fun loadSigningConfig(): Properties {
    val properties = Properties()
    val file = rootProject.file("key.properties")
    if (file.exists()) {
        file.inputStream().use { properties.load(it) }
    }
    return properties
}

fun hasReleaseSigning(): Boolean {
    val env = System.getenv()
    val props = loadSigningConfig()
    val hasEnvKey = !env["ANDROID_KEYSTORE"].isNullOrBlank()
    val hasFileKey = props.getProperty("storeFile") != null &&
        props.getProperty("storePassword") != null &&
        props.getProperty("keyAlias") != null &&
        props.getProperty("keyPassword") != null
    return hasEnvKey || hasFileKey
}

android {
    namespace = "com.nextgen.expenseflowapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    signingConfigs {
        if (hasReleaseSigning()) {
            create("release") {
                val props = loadSigningConfig()
                val env = System.getenv()

                val storeFileValue = env["ANDROID_KEYSTORE"].takeUnless { it.isNullOrBlank() }
                    ?: props.getProperty("storeFile")
                storeFile = file(storeFileValue)
                storePassword = env["ANDROID_KEYSTORE_PASSWORD"].takeUnless { it.isNullOrBlank() }
                    ?: props.getProperty("storePassword")
                keyAlias = env["ANDROID_KEY_ALIAS"].takeUnless { it.isNullOrBlank() }
                    ?: props.getProperty("keyAlias")
                keyPassword = env["ANDROID_KEY_PASSWORD"].takeUnless { it.isNullOrBlank() }
                    ?: props.getProperty("keyPassword")
            }
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.nextgen.expenseflowapp"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Temporarily disabled to isolate ProGuard/R8 as the cause of
            // release-only failures. Re-enable after verification.
            isMinifyEnabled = true
            isShrinkResources = true
            // Signing with the release key from key.properties (local) or
            // ANDROID_KEYSTORE_* env vars (CI). Fall back to debug keys.
            signingConfig = if (hasReleaseSigning()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
