# android-kotlin

Android app, Gradle Kotlin DSL, view binding, no Compose. Dependencies are
declared in the version catalog at `gradle/libs.versions.toml` — nothing is
version-pinned inline in `app/build.gradle.kts`.

```sh
./gradlew :app:assembleDebug
```

Requires a local Android SDK (point `local.properties` at it, or set
`ANDROID_HOME`) and a JDK 17 or newer to run Gradle on, which is what AGP 8.7
needs. The wrapper is pinned to Gradle 8.14.4.

All feature decisions go through the `FeatureFlags` interface
(`app/src/main/java/com/example/darkstore/FeatureFlags.kt`). The instance is
created in `DarkStoreApplication.onCreate` and read through
`StorefrontViewModel`.

