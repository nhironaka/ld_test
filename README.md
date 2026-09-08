# ld_test

`apps/` is a fixture monorepo for testing whether tooling can install and
correctly wire a LaunchDarkly SDK into an app it has never seen. Every app
under `apps/` is a working, idiomatic project in its ecosystem — and none of
them have a LaunchDarkly SDK installed. That is the point.

The well-trodden path (TypeScript / Node / React) is deliberately absent.
There is no `package.json` anywhere in this repo, so nothing can fall back to
the JavaScript happy path.

The other top-level directories are hand-built demos that *already* have an
SDK wired up (`LDButtonDemo`, `experimentation` — iOS/Swift;
`android-button-demo` — Android/Kotlin; `PostHogDemo` — a PostHog
comparison). They are reference points, not install fixtures.

## The fixture apps

| Directory | Stack | Dependency manifest | Expected SDK |
| --- | --- | --- | --- |
| `apps/ruby-sinatra` | Sinatra 4, Puma, Rack | `Gemfile` (Bundler) | `launchdarkly-server-sdk` (RubyGems) |
| `apps/rust-axum` | Axum 0.8, Tokio | `Cargo.toml` | `launchdarkly-server-sdk` (crates.io) |
| `apps/dotnet-api` | ASP.NET Core 8 minimal API | `DarkStore.Api.csproj` | `LaunchDarkly.ServerSdk` (NuGet) |
| `apps/php-slim` | Slim 4, PHP-DI, PSR-7 | `composer.json` | `launchdarkly/server-sdk` (Packagist) |
| `apps/android-kotlin` | Android, Gradle Kotlin DSL, view binding | `gradle/libs.versions.toml` | `com.launchdarkly:launchdarkly-android-client-sdk` (Maven) |

All five expose the same three endpoints or screens and make the same three
feature decisions. See [FLAGS.md](FLAGS.md) for the flag keys and the
evaluation attributes each app already collects.

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
  hold a streaming connection, so a correct install needs a persistent store
  or a sidecar rather than per-request polling. The SDK also requires the
  `apcu` extension from version 6.6 on. Dependencies are container-bound in
  `src/bootstrap.php`.
- **android-kotlin** — a client-side SDK, not server-side. Dependencies must
  go through the version catalog (`gradle/libs.versions.toml`), not inline in
  `app/build.gradle.kts`. Initialization happens in `Application.onCreate`
  and must not block the main thread; the seam exposes `identify` for
  login/logout and returns `Flow`s because values change at runtime.

## Verification status of the baseline

The apps were checked as far as the local toolchain allows:

| App | Status |
| --- | --- |
| `apps/rust-axum` | builds, runs, all endpoints verified by hand, `cargo clippy` clean |
| `apps/ruby-sinatra` | `bundle install` succeeds, `bundle exec rake test` passes (4 tests) |
| `apps/dotnet-api` | not compiled — no `dotnet` on this machine |
| `apps/php-slim` | not linted — no `php` on this machine |
| `apps/android-kotlin` | not built — no Android SDK or Gradle on this machine |

If a baseline build failure turns up in one of the unverified apps, fix it
before grading an install run, so the failure is not mistaken for the
tooling's fault.

`Gemfile.lock` and `Cargo.lock` are committed, as they would be in a real
application, so a correct install has to update the lockfile as well as the
manifest. `apps/php-slim` has no `composer.lock` yet only because there is no
PHP toolchain here to generate one.
