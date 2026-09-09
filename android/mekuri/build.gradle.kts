import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.compose.compiler)
}

group = "app.mekuri"
version = "0.1.0"

android {
    namespace = "app.mekuri"
    compileSdk = 35

    defaultConfig {
        minSdk = 33
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        compose = true
    }

    sourceSets {
        getByName("main").kotlin.srcDir("src/main/kotlin")
        getByName("test").kotlin.srcDir("src/test/kotlin")
        getByName("androidTest").kotlin.srcDir("src/androidTest/kotlin")
    }
}

kotlin {
    explicitApi()

    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

dependencies {
    api(platform(libs.androidx.compose.bom))
    api(libs.androidx.compose.ui.geometry)
    api(libs.androidx.compose.animation.core)
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.foundation.layout)
    implementation(libs.androidx.compose.ui.graphics)

    testImplementation(libs.junit)

    androidTestImplementation(platform(libs.androidx.compose.bom))
    androidTestImplementation(libs.junit)
    androidTestImplementation(libs.androidx.test.runner)
    androidTestImplementation(libs.androidx.test.ext.junit)
    androidTestImplementation(libs.androidx.test.uiautomator)
    androidTestImplementation(libs.androidx.compose.ui.test.junit4)
    androidTestImplementation(libs.androidx.compose.foundation)
    debugImplementation(libs.androidx.compose.ui.test.manifest)
}

val maxKotlinFileLines = 600

val checkFileLength = tasks.register("checkFileLength") {
    group = "verification"
    description = "Fails if any hand-written Kotlin file exceeds $maxKotlinFileLines lines."
    val sources = layout.projectDirectory.dir("src")
    inputs.dir(sources)
    doLast {
        val offenders = sources.asFile.walkTopDown()
            .filter { it.isFile && it.extension == "kt" }
            .map { it to it.readLines().size }
            .filter { (_, lines) -> lines > maxKotlinFileLines }
            .sortedByDescending { it.second }
            .toList()
        if (offenders.isNotEmpty()) {
            val detail = offenders.joinToString("\n") { (file, lines) ->
                "  $lines lines  ${file.relativeTo(projectDir)}"
            }
            throw GradleException(
                buildString {
                    appendLine("God-file guard failed: ${offenders.size} Kotlin file(s) exceed $maxKotlinFileLines lines.")
                    append(detail)
                },
            )
        }
    }
}

tasks.named("check").configure { dependsOn(checkFileLength) }
