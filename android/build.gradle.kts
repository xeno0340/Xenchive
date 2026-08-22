// Top-level build file for all sub-projects/modules (Kotlin DSL).
// Keep this minimal so it doesn't conflict with Flutter's managed plugins/versions.

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ---- Optional: centralize build outputs (nice for CI / clean folder tree)
val newBuildDir: Directory =
    rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    // Ensure :app is evaluated first (safe for Flutter projects)
    project.evaluationDependsOn(":app")
}

// Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
