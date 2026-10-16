plugins {
  // ...

  // Add the dependency for the Google services Gradle plugin
  id("com.google.gms.google-services") version "4.4.4" apply false

}

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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    val project = this
    // This hook runs when the 'android' plugin is applied to a subproject (like a library)
    project.plugins.withId("com.android.library") {
        project.extensions.configure<com.android.build.api.variant.LibraryAndroidComponentsExtension> {
            finalizeDsl { dsl ->
                if (dsl.namespace == null) {
                    dsl.namespace = project.group.toString().ifEmpty { "com.example.${project.name.replace("-", ".")}" }
                }
                dsl.compileOptions.sourceCompatibility = JavaVersion.VERSION_17
                dsl.compileOptions.targetCompatibility = JavaVersion.VERSION_17
            }
        }
        project.tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
    }
}