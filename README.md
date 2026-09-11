# ld_test

`apps/` is a fixture monorepo for testing whether tooling can install and
correctly wire a LaunchDarkly SDK into an app it has never seen. Every app
under `apps/` is a working, idiomatic project in its ecosystem, and started out
with no LaunchDarkly SDK installed. That is the point.

Three of them now have one: `apps/ruby-sinatra` and `apps/dotnet-api` were
installed into first, then `apps/php-slim`, so they double as a second answer
key alongside the demos. The pre-install state of the first two is commit
`510b98c`, and of `apps/php-slim` is commit `d206bef`; the remaining five apps
are untouched fixtures.

The well-trodden path (TypeScript / Node / React) is deliberately absent.
There is no `package.json` anywhere in this repo, so nothing can fall back to
the JavaScript happy path.

The three button-copy demos are fixtures too. `LDButtonDemo` and
`experimentation` (iOS/Swift, XcodeGen) and `android-button-demo`
(Android/Kotlin, Compose) each had a working LaunchDarkly integration; the SDK
has been stripped out of all three and replaced with the same kind of seam the
`apps/` fixtures use. `PostHogDemo` is an untouched PostHog comparison app.

## The answer key

The demos' working integrations are preserved in git, so the diff is a
reference for what a correct install produces:

```sh
git diff 39a3129 HEAD -- LDButtonDemo experimentation android-button-demo
```

`39a3129` is the demos exactly as they were with the SDK wired up; `HEAD` is
the same apps with it removed. Reverse the diff and you have a known-good
install for iOS and Android to grade against. The `apps/` fixtures have no such
reference — they were never integrated.

## The fixture apps

| Directory | Stack | Dependency manifest | Expected SDK |
| --- | --- | --- | --- |
| `apps/ruby-sinatra` | Sinatra 4, Puma, Rack | `Gemfile` (Bundler) | `launchdarkly-server-sdk` (RubyGems) |
| `apps/rust-axum` | Axum 0.8, Tokio | `Cargo.toml` | `launchdarkly-server-sdk` (crates.io) |
| `apps/dotnet-api` | ASP.NET Core 8 minimal API | `DarkStore.Api.csproj` | `LaunchDarkly.ServerSdk` (NuGet) |
| `apps/php-slim` | Slim 4, PHP-DI, PSR-7 | `composer.json` | `launchdarkly/server-sdk` (Packagist) |
| `apps/android-kotlin` | Android, Gradle Kotlin DSL, view binding | `gradle/libs.versions.toml` | `com.launchdarkly:launchdarkly-android-client-sdk` (Maven) |
| `LDButtonDemo` | UIKit, XcodeGen | `project.yml` | `launchdarkly/ios-client-sdk` (SwiftPM) |
| `experimentation` | UIKit, XcodeGen, three tabs | `project.yml` | `launchdarkly/ios-client-sdk` (SwiftPM) |
| `android-button-demo` | Compose, Gradle Kotlin DSL | `app/build.gradle.kts` | `com.launchdarkly:launchdarkly-android-client-sdk` (Maven) |

The five `apps/` expose the same three endpoints or screens and make the same
three feature decisions; the three demos share a smaller button-copy flag set.
See [FLAGS.md](FLAGS.md) for the flag keys and the evaluation attributes each
app already collects.

## The shape of the test

Every app has exactly one place where feature decisions live, already
abstracted behind a seam with a doc comment stating the intent:

| Directory | Seam |
| --- | --- |
| `apps/ruby-sinatra` | `lib/feature_flags.rb` — `DarkStore::FeatureFlags` |
| `apps/rust-axum` | `src/flags.rs` — `Flags` |
| `apps/dotnet-api` | `FeatureFlags.cs` — `IFeatureFlags` / `StaticFeatureFlags` |
| `apps/php-slim` | `src/Support/FeatureFlags.php` — `FeatureFlags` interface |
| `apps/android-kotlin` | `.../darkstore/FeatureFlags.kt` — `FeatureFlags` interface |
| `LDButtonDemo` | `Sources/FeatureFlags.swift` — `FeatureFlags` protocol |
| `experimentation` | `Sources/FeatureFlags.swift` — `FeatureFlags` protocol |
| `android-button-demo` | `.../ldbuttondemo/FeatureFlags.kt` — `FeatureFlags` interface |

A correct install should: add the right package to the right manifest, read
the SDK key from the mechanism the app already uses for configuration, build
an evaluation context from the attributes the app already collects, replace
the hardcoded returns, and keep the app building.

## What each app is actually testing

- **ruby-sinatra** — Bundler, not RubyGems directly. Also: Puma forks workers,
  so a naive client initialized at load time breaks. The seam has a
  `shutdown` hook for flushing analytics.
- **rust-axum** — a server-side SDK for a language where many vendors do not
  ship one. `Flags::initialize` is `async` and `Flags` is shared behind `Arc`,
  so whatever goes in must be `Send + Sync`.
- **dotnet-api** — `TreatWarningsAsErrors` is on and nullable reference types
  are enabled, so sloppy generated code will not compile. The SDK key comes
  from `IConfiguration` (`LaunchDarkly:SdkKey`), not from an env var read
  directly.
- **php-slim** — the hardest runtime model: PHP has no long-lived process to
  hold a streaming connection, so the SDK fetches a flag per evaluation and a
  latency-sensitive install needs a Relay Proxy or a cache that outlives the
  request. The `apcu` extension is optional, not required: `LDClient` uses it
  for a stable instance id when present, and only throws if you explicitly set
  `apc_expiration`. Dependencies are container-bound in `src/bootstrap.php`.
- **android-kotlin** — a client-side SDK, not server-side. Dependencies must
  go through the version catalog (`gradle/libs.versions.toml`), not inline in
  `app/build.gradle.kts`. Initialization happens in `Application.onCreate`
  and must not block the main thread; the seam exposes `identify` for
  login/logout and returns `Flow`s because values change at runtime.
- **LDButtonDemo / experimentation** — SwiftPM through XcodeGen, so the
  dependency belongs in `project.yml`'s `packages:` block and the target's
  `dependencies:` list. Editing `.xcodeproj` directly is wrong: it is
  regenerated by `xcodegen generate`. `experimentation` additionally exercises
  `identify` on login and a `data` payload on the metric call.
- **android-button-demo** — inline dependency strings in
  `app/build.gradle.kts`, not a version catalog, so it tests the other Gradle
  convention. `minSdk` is 21, which rules out anything gated on API 24. The
  seam returns a `Future` that `MainActivity` awaits on `Dispatchers.IO`.

## Verification status of the baseline

The apps were checked as far as the local toolchain allows:

| App | Status |
| --- | --- |
| `apps/rust-axum` | builds, runs, all endpoints verified by hand, `cargo clippy` clean |
| `apps/ruby-sinatra` | `bundle exec rake test` passes (4 tests). With the SDK installed, `bundle install` needs the zlib and openssl gems, so the install itself was resolved (`bundle lock`) but not compiled where it was written |
| `apps/dotnet-api` | `dotnet build` clean with `TreatWarningsAsErrors`, runs, all endpoints verified by hand with and without an SDK key |
| `apps/php-slim` | every route returned 500 until commit `85dba04`: Slim binds route handlers to the container with `Closure::bindTo`, which returns `null` for a `static` closure, so its `: callable` return type threw. `tests/StorefrontTest.php` was failing with it. Now lints clean and serves; verified by hand with no key, with an unreachable LaunchDarkly, and against served variations |
| `apps/android-kotlin` | `./gradlew :app:assembleDebug` succeeds (Gradle 8.14.4, JDK 17) |
| `LDButtonDemo` | `xcodebuild` succeeds for the iOS Simulator |
| `experimentation` | `xcodebuild` succeeds for the iOS Simulator |
| `android-button-demo` | `./gradlew :app:assembleDebug` succeeds; no LaunchDarkly left on `debugRuntimeClasspath` |

If a baseline build failure turns up in one of the unverified apps, fix it
before grading an install run, so the failure is not mistaken for the
tooling's fault.

`Gemfile.lock` and `Cargo.lock` are committed, as they would be in a real
application, so a correct install has to update the lockfile as well as the
manifest. `apps/php-slim` still has no `composer.lock`: there is a PHP toolchain
here now, but packagist is unreachable from it, so `composer install` cannot
resolve one and a handwritten lockfile would be a fiction. The iOS demos
likewise have no `Package.resolved` — installing a Swift package creates one.

## A note on keys

The demos' `Config` files carry placeholders (`mob-YOUR-MOBILE-KEY`,
`phc_YOUR_PROJECT_API_KEY`), not real credentials. The real values are in
`.local-credentials.md`, which is gitignored. Keep it that way: a key committed
here stays in history even if a later commit removes it.
