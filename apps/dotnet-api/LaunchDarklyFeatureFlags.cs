using LaunchDarkly.Logging;
using LaunchDarkly.Sdk;
using LaunchDarkly.Sdk.Server;

namespace DarkStore.Api;

/// <summary>
/// Evaluates the service's flags against LaunchDarkly. Registered as a
/// singleton, which is what the SDK wants: one client per process, holding a
/// streaming connection and an in-memory flag store, so evaluation on the
/// request path is a local lookup with no network call.
/// </summary>
/// <remarks>
/// Every evaluation passes the hardcoded default from
/// <see cref="FeatureFlagDefaults"/>, which the SDK returns if it has no value
/// for the flag yet, the flag does not exist, or its variation has the wrong
/// type. An unreachable LaunchDarkly therefore degrades to the behaviour this
/// service had before the SDK was installed rather than failing requests.
/// </remarks>
public sealed class LaunchDarklyFeatureFlags : IFeatureFlags
{
    private static readonly TimeSpan StartWaitTime = TimeSpan.FromSeconds(5);

    private readonly LdClient _client;
    private readonly ILogger<LaunchDarklyFeatureFlags> _logger;

    public LaunchDarklyFeatureFlags(
        IConfiguration configuration,
        ILoggerFactory loggerFactory,
        ILogger<LaunchDarklyFeatureFlags> logger)
    {
        _logger = logger;

        var sdkKey = configuration["LaunchDarkly:SdkKey"];

        if (string.IsNullOrWhiteSpace(sdkKey))
        {
            throw new InvalidOperationException(
                "LaunchDarkly:SdkKey is not configured; register StaticFeatureFlags instead.");
        }

        _client = new LdClient(Configuration.Builder(sdkKey)
            .StartWaitTime(StartWaitTime)
            .Logging(Components.Logging(Logs.CoreLogging(loggerFactory)))
            .Build());

        if (!_client.Initialized)
        {
            _logger.LogWarning(
                "LaunchDarkly did not connect within {Seconds}s; serving flag defaults until it does",
                StartWaitTime.TotalSeconds);
        }
    }

    public bool CheckoutRedesign(Actor actor) => _client.BoolVariation(
        FeatureFlagKeys.CheckoutRedesign, ContextFor(actor), FeatureFlagDefaults.CheckoutRedesign);

    public string BannerCopy(Actor actor) => _client.StringVariation(
        FeatureFlagKeys.BannerCopy, ContextFor(actor), FeatureFlagDefaults.BannerCopy);

    public int MaxCartItems(Actor actor) => _client.IntVariation(
        FeatureFlagKeys.MaxCartItems, ContextFor(actor), FeatureFlagDefaults.MaxCartItems);

    /// <summary>
    /// The request's actor as a single <c>user</c> context. <c>email</c> is a
    /// built-in attribute; <c>plan</c> and <c>country</c> are custom ones, and
    /// targeting rules address them by those names.
    /// </summary>
    private static Context ContextFor(Actor actor)
    {
        var context = Context.Builder(actor.Key)
            .Set("plan", actor.Plan)
            .Set("country", actor.Country);

        if (!string.IsNullOrEmpty(actor.Email))
        {
            context.Set("email", actor.Email);
        }

        return context.Build();
    }

    /// <summary>
    /// Runs on host shutdown so any buffered analytics are flushed before the
    /// process exits.
    /// </summary>
    public ValueTask DisposeAsync()
    {
        _client.Flush();
        _client.Dispose();

        return ValueTask.CompletedTask;
    }
}
