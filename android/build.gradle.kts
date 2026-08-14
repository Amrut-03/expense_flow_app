allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    val alignKotlinToJava = {
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            val variant = name.removePrefix("compile").removeSuffix("Kotlin")
            val javaTarget = (tasks.findByName("compile${variant}JavaWithJavac") as? JavaCompile)
                ?.targetCompatibility?.trim()
            val jvm = when (javaTarget) {
                "17" -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
                "11" -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
                "1.8", "8" -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8
                else -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
            }
            compilerOptions {
                jvmTarget.set(jvm)
            }
        }
    }

    if (project.state.executed) {
        alignKotlinToJava()
    } else {
        afterEvaluate {
            alignKotlinToJava()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
