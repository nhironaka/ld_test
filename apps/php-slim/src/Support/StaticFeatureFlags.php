<?php

declare(strict_types=1);

namespace DarkStore\Support;

use Psr\Log\LoggerInterface;

/**
 * Hardcoded defaults, used when no SDK key is configured. When one is,
 * `src/bootstrap.php` binds {@see LaunchDarklyFeatureFlags} instead, and the
 * constants below become the values it falls back to.
 */
final class StaticFeatureFlags implements FeatureFlags
{
    public function __construct(
        private readonly ?string $sdkKey = null,
        private readonly ?LoggerInterface $logger = null,
    ) {
        if ($this->sdkKey === null || $this->sdkKey === '') {
            $this->logger?->warning('No SDK key configured; serving hardcoded flag defaults');
        }
    }

    public function checkoutRedesign(Actor $actor): bool
    {
        return FeatureFlagDefaults::CHECKOUT_REDESIGN;
    }

    public function bannerCopy(Actor $actor): string
    {
        return FeatureFlagDefaults::BANNER_COPY;
    }

    public function maxCartItems(Actor $actor): int
    {
        return FeatureFlagDefaults::MAX_CART_ITEMS;
    }
}
