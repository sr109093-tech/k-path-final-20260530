import java.util.Properties
import java.nio.charset.StandardCharsets

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.reader(StandardCharsets.UTF_8).use { reader ->
        localProperties.load(reader)
    }
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode") ?: "1"
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.0"

android {
    namespace = "com.example.my_gps_app"
    
    // ⚙️ 에러 해결 핵심: 패키지 요구사항에 맞춰 compileSdk를 36으로 올렸습니다.
    compileSdk = 36 
    
    // ⚙️ 에러 해결 핵심: NDK 버전을 요구 규격인 28.2.13676358로 지정했습니다.
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.my_gps_app"
        minSdk = flutter.minSdkVersion
        // ⚙️ targetSdk도 compileSdk와 동일하게 36으로 상향 조정했습니다.
        targetSdk = 36
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib:2.2.20")
}
