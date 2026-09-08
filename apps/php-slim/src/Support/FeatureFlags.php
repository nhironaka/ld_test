<?php

declare(strict_types=1);

namespace DarkStore\Support;

/**
 * Central seam for every runtime feature decision in the service. Resolved
 * from the container once per request.
 */
interface FeatureFlags
{
    /** Boolean rollout: gates the rebuilt checkout funnel. */
    public function checkoutRedesign(Actor $actor): bool;

    /** String variation: marketing copy for the storefront banner. */
    public function bannerCopy(Actor $actor): string;

    /** Numeric variation: per-plan cart ceiling. */
    public function maxCartItems(Actor $actor): int;
}
