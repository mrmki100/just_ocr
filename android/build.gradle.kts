plugins {
  // Add the dependency for the Google services Gradle plugin
  id("com.google.gms.google-services") version "4.5.0" apply false
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
    val patchNamespace: (Project) -> Unit = { proj ->
        val androidExt = proj.extensions.findByName("android")
        if (androidExt != null) {
            try {
                val currentNs = androidExt.javaClass.getMethod("getNamespace").invoke(androidExt)
                if (currentNs == null) {
                    val groupStr = proj.group.toString()
                    val newNs = if (groupStr.isNotBlank()) groupStr else "com.example.${proj.name.replace("-", "_")}"
                    androidExt.javaClass.getMethod("setNamespace", java.lang.String::class.java).invoke(androidExt, newNs)
                }
            } catch (e: Exception) {
                // Ignore if method is unavailable
            }
        }
    }

    // Check if the project is already evaluated to avoid the crash
    if (this.state.executed) {
        patchNamespace(this)
    } else {
        this.afterEvaluate { patchNamespace(this) }
    }
}
subprojects {
    val forceUpgrade: Project.() -> Unit = {
        plugins.withId("com.android.library") {
            extensions.configure<com.android.build.api.dsl.LibraryExtension> {
                compileSdk = 34
                
                // ONLY fix Isar, leave file_picker alone!
                if (project.name == "isar_flutter_libs" && namespace == null) {
                    namespace = "dev.isar.isar_flutter_libs"
                }
            }
        }
        plugins.withId("com.android.application") {
            extensions.configure<com.android.build.api.dsl.ApplicationExtension> {
                compileSdk = 34
            }
        }
    }

    // Safely apply the fix without crashing on already evaluated projects
    if (state.executed) {
        forceUpgrade()
    } else {
        afterEvaluate { forceUpgrade() }
    }
}
