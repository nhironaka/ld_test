# dotnet-api

ASP.NET Core 8 minimal API.

```sh
dotnet restore
dotnet run          # http://localhost:5080
```

All feature decisions go through `IFeatureFlags` (`FeatureFlags.cs`), registered
as a singleton in `Program.cs`. `StaticFeatureFlags` is the current
hardcoded implementation.

The SDK key is read from configuration at `LaunchDarkly:SdkKey`
(`appsettings.json`), which is overridable by the
`LaunchDarkly__SdkKey` environment variable.
