import com.android.build.gradle.BaseExtension

allprojects {
    repositories {
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/central") }
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
    fun configureAndroidSdk() {
        extensions.findByType(BaseExtension::class.java)?.apply {
            buildToolsVersion = "36.1.0"
            ndkVersion = "30.0.14904198"
        }
    }
    pluginManager.withPlugin("com.android.application") { configureAndroidSdk() }
    pluginManager.withPlugin("com.android.library") { configureAndroidSdk() }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
