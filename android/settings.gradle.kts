pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        val propertiesFile = File(settingsDir, "local.properties")
        if (propertiesFile.exists()) {
            propertiesFile.reader(java.nio.charset.StandardCharsets.UTF_8).use { reader ->
                properties.load(reader)
            }
        }
        val sdkPath = properties.getProperty("flutter.sdk")
        if (sdkPath == null) {
            throw GradleException("flutter.sdk not set in local.properties")
        }
        sdkPath
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
    // ⚙️ 최신 플러터 요구 사양에 맞춰 빌드 엔진 버전을 상향 조정했습니다.
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")