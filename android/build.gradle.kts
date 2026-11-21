buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // গুগলের সার্ভিস চালু করার জন্য
        classpath("com.google.gms:google-services:4.4.1")
    }
}

allprojects {
    repositories {
// ... বাকি কোড যেমন ছিল তেমনই থাকবে
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
