using LaunchDarkly.Logging;
using LaunchDarkly.Sdk.Server;
using LaunchDarkly.Sdk.Server.Interfaces;

namespace DarkStore.Api;

/// <summary>
/// Registers the <see cref="IFeatureFlags"/> seam.
/// </summary>
public static class FeatureFlagsServiceCollectionExtensions
{
    /// <summary>
    /// How long startup waits for the first payload of flag data. If it elapses
    /// the app still starts and serves fallbacks, catching up once the stream
    /// connects — a slow LaunchDarkly is never a failed deploy.
    /// </summary>
    private static readonly TimeSpan StartWaitTime = TimeSpan.FromSeconds(5);

    /// <summary>
    /// Binds <see cref="IFeatureFlags"/> to LaunchDarkly when an SDK key is
    /// configured at <c>LaunchDarkly:SdkKey</c> (overridable with the
    /// <c>LaunchDarkly__SdkKey</c> environment variable), and to
    /// <see cref="StaticFeatureFlags"/> when it is absent. That keeps local
    /// development, tests, and CI working with no credential and no outbound
    /// network calls.
    /// </summary>
    public static IServiceCollection AddFeatureFlags(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var sdkKey = configuration["LaunchDarkly:SdkKey"];

        if (string.IsNullOrWhiteSpace(sdkKey))
        {
            return services.AddSingleton<IFeatureFlags, StaticFeatureFlags>();
        }

        services.AddSingleton<ILdClient>(provider =>
        {
            // Route the SDK's own diagnostics through the host's logging so its
            // connection state shows up alongside everything else.
            var loggerFactory = provider.GetRequiredService<ILoggerFactory>();

            var config = Configuration.Builder(sdkKey)
                .Logging(Components.Logging(Logs.CoreLogging(loggerFactory)))
                .StartWaitTime(StartWaitTime)
                .Build();

            return new LdClient(config);
        });

        services.AddSingleton<IFeatureFlags, LaunchDarklyFeatureFlags>();

        // Build the client while the host is starting rather than lazily on the
        // first request, so StartWaitTime is paid at boot instead of showing up
        // as latency for whoever happens to arrive first.
        services.AddHostedService<FeatureFlagsWarmup>();

        return services;
    }

    /// <summary>
    /// Exists only for its constructor: resolving the singleton forces the
    /// LaunchDarkly client to connect during host startup.
    /// </summary>
    private sealed class FeatureFlagsWarmup : IHostedService
    {
        public FeatureFlagsWarmup(IFeatureFlags flags)
        {
            _ = flags;
        }

        public Task StartAsync(CancellationToken cancellationToken) => Task.CompletedTask;

        public Task StopAsync(CancellationToken cancellationToken) => Task.CompletedTask;
    }
}
