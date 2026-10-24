import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// key.properties は android/ 直下に置く（.gitignore 済み）。
// 存在しない場合はデバッグ署名にフォールバックし、release ビルドが失敗しないようにする。
val keystorePropertiesFile = rootProject.file("key.properties")
val hasKeystore = keystorePropertiesFile.exists()
val keystoreProperties = Properties().apply {
    if (hasKeystore) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}

// AdMob のアプリ ID は android/admob.properties（.gitignore 済み）から読み込む。
// 用意されていない場合は Google 公式のテスト用アプリ ID にフォールバックする。
val admobPropertiesFile = rootProject.file("admob.properties")
val admobProperties = Properties().apply {
    if (admobPropertiesFile.exists()) {
        FileInputStream(admobPropertiesFile).use { load(it) }
    }
}
val testAdmobAppId = "ca-app-pub-3940256099942544~3347511713"
val resolvedAdmobAppId: String = admobProperties.getProperty("admobAppId", testAdmobAppId)
if (resolvedAdmobAppId == testAdmobAppId) {
    logger.warn(
        "[AdMob] android/admob.properties が無いため、テスト用アプリ ID でビルドします。" +
            "ストア配信用のビルドでは admob.properties を配置してください。"
    )
}

android {
    namespace = "com.techtan.tech_tan"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.techtan.tech_tan"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // AndroidManifest.xml の ${admobAppId} に差し込む
        manifestPlaceholders["admobAppId"] = resolvedAdmobAppId
    }

    signingConfigs {
        if (hasKeystore) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasKeystore) {
                signingConfigs.getByName("release")
            } else {
                // key.properties が無い環境（CI など）でも release ビルドを通すための暫定署名。
                // ストア配信用のビルドでは必ず android/key.properties を配置すること。
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
