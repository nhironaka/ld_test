<?php

declare(strict_types=1);

namespace DarkStore\Support;

/**
 * The flag keys this service evaluates, as they are defined in LaunchDarkly.
 * See FLAGS.md at the repository root.
 */
final class FeatureFlagKeys
{
    public const CHECKOUT_REDESIGN = 'checkout-redesign';
    public const BANNER_COPY = 'banner-copy';
    public const MAX_CART_ITEMS = 'max-cart-items';

    private function __construct()
    {
    }
}
