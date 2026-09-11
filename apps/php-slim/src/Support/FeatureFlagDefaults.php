<?php

declare(strict_types=1);

namespace DarkStore\Support;

/**
 * The values served when LaunchDarkly cannot answer: no SDK key configured,
 * LaunchDarkly unreachable, the flag missing, or its variation of an
 * unexpected type. They are what this service returned before the SDK was
 * installed, so a degraded LaunchDarkly serves the old behaviour instead of
 * failing requests.
 *
 * Both {@see StaticFeatureFlags} and {@see LaunchDarklyFeatureFlags} read them
 * from here so the fallbacks are defined once.
 */
final class FeatureFlagDefaults
{
    public const CHECKOUT_REDESIGN = false;
    public const BANNER_COPY = 'Free shipping on orders over $50';
    public const MAX_CART_ITEMS = 25;

    private function __construct()
    {
    }
}
