// ✅ Définition des dépôts globaux
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ✅ Déplacement du dossier build (optionnel mais propre)
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

// ✅ Tâche clean
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// ======================================================
// 🔹 Ajout pour Firebase / Google Services
// ======================================================
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Plugin Google Services (obligatoire pour lire google-services.json)
        classpath("com.google.gms:google-services:4.4.0")
    }
}
