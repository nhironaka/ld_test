namespace DarkStore.Api;

/// <summary>
/// Central seam for every runtime feature decision in the service. Registered
/// as a singleton, so implementations must be thread-safe and cheap to call
/// on the request path.
/// </summary>
public interface IFeatureFlags : IAsyncDisposable
{
    /// <summary>Boolean rollout: gates the rebuilt checkout funnel.</summary>
    bool CheckoutRedesign(Actor actor);

    /// <summary>String variation: marketing copy for the storefront banner.</summary>
    string BannerCopy(Actor actor);

    /// <summary>Numeric variation: per-plan cart ceiling.</summary>
    int MaxCartItems(Actor actor);
}

/// <summary>
/// Hardcoded defaults. The intent is to replace this with an implementation
/// that consults a remote flag evaluation service, keyed off the current
/// request's actor, so we can roll changes out gradually instead of shipping
/// a deploy per toggle.
/// </summary>
public sealed class StaticFeatureFlags : IFeatureFlags
{
    private readonly ILogger<StaticFeatureFlags> _logger;

    public StaticFeatureFlags(IConfiguration configuration, ILogger<StaticFeatureFlags> logger)
    {
        _logger = logger;

        if (string.IsNullOrEmpty(configuration["LaunchDarkly:SdkKey"]))
        {
            _logger.LogWarning("No SDK key configured; serving hardcoded flag defaults");
        }
    }

    public bool CheckoutRedesign(Actor actor) => false;

    public string BannerCopy(Actor actor) => "Free shipping on orders over $50";

    public int MaxCartItems(Actor actor) => 25;

    /// <summary>
    /// Runs on host shutdown so any buffered analytics are flushed before the
    /// process exits.
    /// </summary>
    public ValueTask DisposeAsync() => ValueTask.CompletedTask;
}
