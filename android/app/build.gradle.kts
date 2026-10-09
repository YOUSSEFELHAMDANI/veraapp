import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val signingProperties = Properties()
val signingPropertiesFile = rootProject.file("key.properties")
if (signingPropertiesFile.exists()) signingProperties.load(FileInputStream(signingPropertiesFile))

android {
    namespace = "com.veraapp.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.veraapp.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = 3
        versionName = "1.0.2"
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
                keyAlias = signingProperties["keyAlias"] as String
                keyPassword = signingProperties["keyPassword"] as String
                storeFile = rootProject.file(signingProperties["storeFile"] as String)
                storePassword = signingProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

// Remove duplicate ic_launcher_foreground.png before AAPT processes resources.
// The canonical foreground resource is drawable/ic_launcher_foreground.xml (VectorDrawable).
// The PNG at drawable/ic_launcher_foreground.png is a stale duplicate that causes
// "duplicate resource name" AAPT2 errors and must be deleted before mergeResources runs.
afterEvaluate {
    tasks.matching { it.name.startsWith("merge") && it.name.endsWith("Resources") }.configureEach {
        doFirst {
            val duplicatePng = file("src/main/res/drawable/ic_launcher_foreground.png")
            if (duplicatePng.exists()) {
                println(">>> Removing duplicate launcher resource: ${duplicatePng.absolutePath}")
                duplicatePng.delete()
            }
            // Also remove the old ic_launcher_foreground.xml from drawable/ since
            // the canonical VectorDrawable is now in drawable-v24/ and the
            // adaptive icons reference ic_launcher_foreground_vec.xml
            val oldXml = file("src/main/res/drawable/ic_launcher_foreground.xml")
            if (oldXml.exists()) {
                println(">>> Removing superseded launcher XML: ${oldXml.absolutePath}")
                oldXml.delete()
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    implementation("androidx.multidex:multidex:2.0.1")
    implementation("com.google.android.material:material:1.13.0")
    implementation("androidx.concurrent:concurrent-futures:1.3.0")
}
