# android-button-demo

Compose app: a button whose label comes from a string flag, and whose clicks
fire a conversion metric. Also renders a second, View-based button through
`AndroidView` so the snippet-style `configureExperimentButton` helper is
exercised too.

**No SDK is installed.** All feature decisions go through the `FeatureFlags`
interface in
`app/src/main/java/com/example/ldbuttondemo/FeatureFlags.kt`; the default
implementation returns each caller's own fallback and drops every event.

```sh
./gradlew :app:assembleDebug
```

Fill in `Config.kt` before expecting real values.

Two details worth honouring when wiring in a real client:

- `FeatureFlags.init` is called from `LDApplication.onCreate` and returns a
  `Future`, which `MainActivity` awaits on `Dispatchers.IO`. It must not block
  the main thread.
- `minSdk` is 21, which rules out `CompletableFuture` and anything else gated
  on API 24 unless core library desugaring is enabled.
