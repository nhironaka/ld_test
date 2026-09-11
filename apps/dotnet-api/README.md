# dotnet-api

ASP.NET Core 8 minimal API.

```sh
dotnet restore
dotnet run          # http://localhost:5080
```

All feature decisions go through `IFeatureFlags` (`FeatureFlags.cs`), registered
as a singleton in `Program.cs` by `AddFeatureFlags`
(`FeatureFlagsRegistration.cs`), which picks the implementation based on whether
an SDK key is configured:

| SDK key | Implementation | Behaviour |
| --- | --- | --- |
| absent | `StaticFeatureFlags` | Hardcoded defaults, no network calls. |
| present | `LaunchDarklyFeatureFlags` | Evaluates against LaunchDarkly. |

The SDK key is read from configuration at `LaunchDarkly:SdkKey`
(`appsettings.json`), which is overridable by the
`LaunchDarkly__SdkKey` environment variable.

```sh
LaunchDarkly__SdkKey=sdk-your-server-side-key dotnet run
```

## LaunchDarkly integration

`LaunchDarkly.ServerSdk` evaluates the three flags in `FLAGS.md`
(`checkout-redesign`, `banner-copy`, `max-cart-items`). Notes on how it is wired:

- **Fallbacks.** Every evaluation passes the matching value from
  `FeatureFlagDefaults` — the same values `StaticFeatureFlags` serves. If the SDK
  has no flag data, loses its connection, or the flag is missing from the
  environment, the request degrades to today's behaviour instead of failing.
- **Targeting attributes.** `Actor` is projected onto a LaunchDarkly context with
  `plan` and `country` set, plus `email` when `X-User-Email` is forwarded.
  Requests with no email are marked anonymous, so unidentified callers do not
  count as distinct users.
- **Request path cost.** The client keeps flag data in memory over a streaming
  connection, so each `*Variation` call is a local lookup with no network round
  trip.
- **Startup.** A hosted service builds the client while the host starts, so the
  5-second `StartWaitTime` is paid at boot rather than by the first request. If
  it elapses, the app still starts and serves fallbacks until the stream
  connects — a slow LaunchDarkly is not a failed deploy.
- **Logging.** SDK diagnostics are bridged into `ILoggerFactory`, so connection
  state appears under the `LaunchDarkly.Sdk.*` categories alongside everything
  else.
- **Shutdown.** Disposing `IFeatureFlags` flushes buffered analytics events
  (2-second bound) before the container disposes the client.
