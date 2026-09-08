<?php

declare(strict_types=1);

namespace DarkStore\Support;

use Psr\Log\LoggerInterface;

/**
 * Hardcoded defaults. The intent is to replace this with an implementation
 * that consults a remote flag evaluation service, keyed off the current
 * request's actor, so we can roll changes out gradually instead of shipping a
 * deploy per toggle.
 *
 * Note that PHP has no long-lived process to hold a streaming connection, so
 * whatever replaces this needs a shared store (or a sidecar) rather than
 * polling on every request.
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
        return false;
    }

    public function bannerCopy(Actor $actor): string
    {
        return 'Free shipping on orders over $50';
    }

    public function maxCartItems(Actor $actor): int
    {
        return 25;
    }
}
