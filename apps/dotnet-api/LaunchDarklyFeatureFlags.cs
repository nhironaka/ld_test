using LaunchDarkly.Sdk;
using LaunchDarkly.Sdk.Server;
using LaunchDarkly.Sdk.Server.Interfaces;

namespace DarkStore.Api;

/// <summary>
/// Evaluates every decision in <see cref="IFeatureFlags"/> against LaunchDarkly.
/// <para>
/// The SDK client holds a streaming connection and an in-memory flag store, so
/// each <c>*Variation</c> call is a local lookup with no network round trip on
/// the request path. It is thread-safe and intended to live for the lifetime of
/// the process, which is why this is registered as a singleton.
/// </para>
/// <para>
/// Every evaluation passes the fallback from <see cref="FeatureFlagDefaults"/>.
/// The SDK returns that value if it has not yet received flag data, loses its
/// connection, or the flag is missing from the environment, so an outage
/// degrades to today's hardcoded behaviour rather than failing the request.
/// </para>
/// </summary>
public sealed class LaunchDarklyFeatureFlags : IFeatureFlags
{
    /// <summary>Bound on how long shutdown waits for buffered events to flush.</summary>
    private static readonly TimeSpan FlushTimeout = TimeSpan.FromSeconds(2);

    private readonly ILdClient _client;
    private readonly ILogger<LaunchDarklyFeatureFlags> _logger;

    public LaunchDarklyFeatureFlags(ILdClient client, ILogger<LaunchDarklyFeatureFlags> logger)
    {
        _client = client;
        _logger = logger;

        if (!_client.Initialized)
        {
            _logger.LogWarning(
                "LaunchDarkly client has not received flag data yet; serving fallbacks until it connects");
        }
    }

    public bool CheckoutRedesign(Actor actor) =>
        _client.BoolVariation(
            FeatureFlagKeys.CheckoutRedesign,
            ToContext(actor),
            FeatureFlagDefaults.CheckoutRedesign);

    public string BannerCopy(Actor actor) =>
        _client.StringVariation(
            FeatureFlagKeys.BannerCopy,
            ToContext(actor),
            FeatureFlagDefaults.BannerCopy);

    public int MaxCartItems(Actor actor) =>
        _client.IntVariation(
            FeatureFlagKeys.MaxCartItems,
            ToContext(actor),
            FeatureFlagDefaults.MaxCartItems);

    /// <summary>
    /// Projects the request's <see cref="Actor"/> onto a LaunchDarkly context so
    /// targeting rules can match on the attributes the service already collects.
    /// </summary>
    private static Context ToContext(Actor actor)
    {
        var builder = Context.Builder(actor.Key)
            .Set("plan", actor.Plan)
            .Set("country", actor.Country);

        if (string.IsNullOrEmpty(actor.Email))
        {
            // No forwarded identity: treat the caller as anonymous so these
            // contexts are not billed or listed as distinct known users.
            builder.Anonymous(true);
        }
        else
        {
            builder.Set("email", actor.Email);
        }

        return builder.Build();
    }

    /// <summary>
    /// Runs on host shutdown so any buffered analytics are flushed before the
    /// process exits. The client itself is registered in the container and
    /// disposed by it, so this only waits for the flush — which blocks, hence
    /// the offload.
    /// </summary>
    public async ValueTask DisposeAsync()
    {
        var flushed = await Task.Run(() => _client.FlushAndWait(FlushTimeout)).ConfigureAwait(false);

        if (!flushed)
        {
            _logger.LogWarning(
                "LaunchDarkly events did not finish flushing within {Timeout}", FlushTimeout);
        }
    }
}
