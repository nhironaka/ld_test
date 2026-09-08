# android-kotlin

Android app, Gradle Kotlin DSL, view binding, no Compose. Dependencies are
declared in the version catalog at `gradle/libs.versions.toml` — nothing is
version-pinned inline in `app/build.gradle.kts`.

```sh
./gradlew :app:assembleDebug     # requires a local Android SDK
```

All feature decisions go through the `FeatureFlags` interface
(`app/src/main/java/com/example/darkstore/FeatureFlags.kt`). The instance is
created in `DarkStoreApplication.onCreate` and read through
`StorefrontViewModel`.

Note that there is no Gradle wrapper JAR checked in — run `gradle wrapper`
once, or open the project in Android Studio.
