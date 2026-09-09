# dotnet-api

ASP.NET Core 8 minimal API.

```sh
dotnet restore
dotnet run          # http://localhost:5080
```

All feature decisions go through `IFeatureFlags` (`FeatureFlags.cs`), registered
as a singleton in `Program.cs`.

The SDK key is read from configuration at `LaunchDarkly:SdkKey`
(`appsettings.json`), which is overridable by the
`LaunchDarkly__SdkKey` environment variable.

## LaunchDarkly

`LaunchDarklyFeatureFlags` (`LaunchDarklyFeatureFlags.cs`) evaluates
`checkout-redesign`, `banner-copy`, and `max-cart-items` through
`LaunchDarkly.ServerSdk`, using a `user` context built from the `X-User-*`
headers `Actor` already reads.

```sh
LaunchDarkly__SdkKey=sdk-... dotnet run
```

`Program.cs` registers it only when a key is configured, and falls back to
`StaticFeatureFlags` when the key is empty, so the service still starts and
serves without one. Both implementations answer with the constants in
`FeatureFlagDefaults`, which are also the defaults passed on every evaluation —
an unreachable LaunchDarkly, a missing flag, or a wrongly typed variation
degrades to the service's previous behaviour instead of failing the request.

The client is resolved during startup rather than on the first request that
needs a flag, so its five-second connect-and-wait is not paid by a customer.
SDK logs are bridged into `ILoggerFactory`, and host shutdown disposes the
client, which flushes buffered analytics events.
