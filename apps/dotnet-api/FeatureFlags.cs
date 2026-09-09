namespace DarkStore.Api;

/// <summary>
/// The values served when no flag service can answer: no SDK key configured,
/// no connection yet, the flag is missing, or its variation has an unexpected
/// type. They are what the service returned before LaunchDarkly was installed.
/// </summary>
public static class FeatureFlagDefaults
{
    public const bool CheckoutRedesign = false;

    public const string BannerCopy = "Free shipping on orders over $50";

    public const int MaxCartItems = 25;
}

/// <summary>
/// The flag keys this service evaluates. See FLAGS.md at the repository root.
/// </summary>
public static class FeatureFlagKeys
{
    public const string CheckoutRedesign = "checkout-redesign";

    public const string BannerCopy = "banner-copy";

    public const string MaxCartItems = "max-cart-items";
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
/// Hardcoded defaults, used when no <c>LaunchDarkly:SdkKey</c> is configured.
/// <see cref="LaunchDarklyFeatureFlags"/> is the implementation that consults
/// LaunchDarkly; <c>Program.cs</c> picks between them at startup.
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

    public bool CheckoutRedesign(Actor actor) => FeatureFlagDefaults.CheckoutRedesign;

    public string BannerCopy(Actor actor) => FeatureFlagDefaults.BannerCopy;

    public int MaxCartItems(Actor actor) => FeatureFlagDefaults.MaxCartItems;

    /// <summary>
    /// Runs on host shutdown so any buffered analytics are flushed before the
    /// process exits.
    /// </summary>
    public ValueTask DisposeAsync() => ValueTask.CompletedTask;
}
