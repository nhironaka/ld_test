namespace DarkStore.Api;

/// <summary>
/// Flag keys as configured in LaunchDarkly. Shared by every
/// <see cref="IFeatureFlags"/> implementation so the keys are declared once.
/// </summary>
public static class FeatureFlagKeys
{
    public const string CheckoutRedesign = "checkout-redesign";
    public const string BannerCopy = "banner-copy";
    public const string MaxCartItems = "max-cart-items";
}

/// <summary>
/// The value each decision falls back to when the flag service cannot be
/// reached, has not finished initializing, or does not define the flag. These
/// are the same values <see cref="StaticFeatureFlags"/> serves, so behaviour is
/// identical whether or not an SDK key is configured.
/// </summary>
public static class FeatureFlagDefaults
{
    public const bool CheckoutRedesign = false;
    public const string BannerCopy = "Free shipping on orders over $50";
    public const int MaxCartItems = 25;
}

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
/// Hardcoded defaults, used when no LaunchDarkly SDK key is configured (local
/// development, tests, CI). When a key is present,
/// <see cref="LaunchDarklyFeatureFlags"/> is registered instead — see
/// <see cref="FeatureFlagsServiceCollectionExtensions.AddFeatureFlags"/>.
/// </summary>
public sealed class StaticFeatureFlags : IFeatureFlags
{
    private readonly ILogger<StaticFeatureFlags> _logger;

    public StaticFeatureFlags(ILogger<StaticFeatureFlags> logger)
    {
        _logger = logger;
        _logger.LogWarning("No LaunchDarkly SDK key configured; serving hardcoded flag defaults");
    }

    public bool CheckoutRedesign(Actor actor) => FeatureFlagDefaults.CheckoutRedesign;

    public string BannerCopy(Actor actor) => FeatureFlagDefaults.BannerCopy;

    public int MaxCartItems(Actor actor) => FeatureFlagDefaults.MaxCartItems;

    /// <summary>
    /// Runs on host shutdown so any buffered analytics are flushed before the
    /// process exits. Nothing is buffered here.
    /// </summary>
    public ValueTask DisposeAsync() => ValueTask.CompletedTask;
}
