allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.layout.buildDirectory.set(rootProject.projectDir.resolve("../build"))

subprojects {
    project.layout.buildDirectory.set(rootProject.layout.buildDirectory.get().asFile.resolve(project.name))
}

subprojects {
    evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}