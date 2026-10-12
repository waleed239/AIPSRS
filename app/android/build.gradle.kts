import org.gradle.api.tasks.Delete

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Set custom build directory
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
    project.evaluationDependsOn(":app")
}

// Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Buildscript (repositories only)
buildscript {
    repositories {
        google()
        mavenCentral()
    }
}

// ❗ No plugins or ext or dependencies here.
// Flutter handles everything automatically.
