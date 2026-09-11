<?php

declare(strict_types=1);

namespace DarkStore\Support;

use LaunchDarkly\LDClient;
use LaunchDarkly\LDContext;
use Psr\Cache\CacheItemPoolInterface;
use Psr\Log\LoggerInterface;
use Psr\Log\NullLogger;

/**
 * Evaluates the flags in {@see FeatureFlagKeys} through LaunchDarkly, keyed off
 * the request's actor, and falls back to {@see FeatureFlagDefaults} whenever the
 * SDK cannot answer.
 *
 * PHP has no long-lived process, so there is no streaming connection to hold
 * and no in-process flag store that survives a request. The PHP SDK is built
 * for that: the client is cheap to construct, and each evaluation fetches the
 * one flag it needs over HTTP rather than relying on state a previous request
 * left behind. Two consequences worth knowing about:
 *
 * - Every evaluation is a round trip, so the two calls `/api/storefront` makes
 *   are two requests to LaunchDarkly. {@see self::CONNECT_TIMEOUT_SECONDS} and
 *   {@see self::TIMEOUT_SECONDS} bound what that can cost a customer when
 *   LaunchDarkly is slow or unreachable; the SDK's own defaults are 3s each.
 * - The fix for the round trips is deployment, not code. Pass `$baseUri`
 *   pointing at a Relay Proxy alongside the app, or hand `$cache` a PSR-6 pool
 *   that outlives the request (APCu, filesystem, Redis) so the SDK's HTTP cache
 *   can revalidate instead of refetch. Both are configuration; see the README.
 */
final class LaunchDarklyFeatureFlags implements FeatureFlags
{
    /**
     * Seconds to wait for a connection to LaunchDarkly, and then for its
     * response. Lower than the SDK's 3s defaults: this service would rather
     * serve a slightly stale banner than hold a storefront request open, and
     * the timeout is paid per evaluation.
     */
    private const CONNECT_TIMEOUT_SECONDS = 1;
    private const TIMEOUT_SECONDS = 2;

    private readonly LoggerInterface $logger;

    private ?LDClient $client = null;

    /**
     * Set once the client has failed to build, so a broken configuration costs
     * one attempt per request rather than one per evaluation.
     */
    private bool $clientUnavailable = false;

    public function __construct(
        private readonly string $sdkKey,
        ?LoggerInterface $logger = null,
        private readonly ?string $baseUri = null,
        private readonly ?string $eventsUri = null,
        private readonly ?CacheItemPoolInterface $cache = null,
    ) {
        $this->logger = $logger ?? new NullLogger();
    }

    /**
     * Delivers the analytics events this request queued.
     *
     * The SDK's event processor flushes in its own destructor, so this is
     * belt-and-braces rather than load-bearing -- it just stops delivery from
     * depending on the order PHP tears nested objects down in. The default
     * publisher hands the payload to a backgrounded `curl`, so it does not
     * delay the response.
     */
    public function __destruct()
    {
        try {
            $this->client?->flush();
        } catch (\Throwable $e) {
            // Never let teardown turn a served response into a fatal error.
            $this->logger->warning('Flushing LaunchDarkly events failed', ['exception' => $e]);
        }
    }

    public function checkoutRedesign(Actor $actor): bool
    {
        $value = $this->variation(
            FeatureFlagKeys::CHECKOUT_REDESIGN,
            $actor,
            FeatureFlagDefaults::CHECKOUT_REDESIGN,
        );

        if (is_bool($value)) {
            return $value;
        }

        $this->warnUnexpectedType(FeatureFlagKeys::CHECKOUT_REDESIGN, 'bool', $value);

        return FeatureFlagDefaults::CHECKOUT_REDESIGN;
    }

    public function bannerCopy(Actor $actor): string
    {
        $value = $this->variation(
            FeatureFlagKeys::BANNER_COPY,
            $actor,
            FeatureFlagDefaults::BANNER_COPY,
        );

        if (is_string($value)) {
            return $value;
        }

        $this->warnUnexpectedType(FeatureFlagKeys::BANNER_COPY, 'string', $value);

        return FeatureFlagDefaults::BANNER_COPY;
    }

    public function maxCartItems(Actor $actor): int
    {
        $value = $this->variation(
            FeatureFlagKeys::MAX_CART_ITEMS,
            $actor,
            FeatureFlagDefaults::MAX_CART_ITEMS,
        );

        if (is_int($value)) {
            return $value;
        }

        // LaunchDarkly has one number type, so a variation authored as 25.0
        // arrives as a PHP float. Accept a whole number as the integer it is;
        // treat a fraction, NAN, INF, or an out-of-range value as an error,
        // since silently truncating a cart limit is worse than serving 25.
        if (
            is_float($value)
            && $value === floor($value)
            && $value >= (float) PHP_INT_MIN
            && $value <= (float) PHP_INT_MAX
        ) {
            return (int) $value;
        }

        $this->warnUnexpectedType(FeatureFlagKeys::MAX_CART_ITEMS, 'int', $value);

        return FeatureFlagDefaults::MAX_CART_ITEMS;
    }

    /**
     * The raw variation, or `$default` when there is no usable client.
     *
     * `LDClient::variation()` does not throw: an unreachable LaunchDarkly, an
     * unknown flag key, or an invalid context is logged by the SDK and returns
     * the default passed here.
     */
    private function variation(string $key, Actor $actor, bool|string|int $default): mixed
    {
        $client = $this->client();

        if ($client === null) {
            return $default;
        }

        return $client->variation($key, $this->context($actor), $default);
    }

    /**
     * The client for this request, built on the first evaluation that needs it
     * so a request that reads no flag -- `/health` -- pays nothing, and `null`
     * if it cannot be built at all.
     */
    private function client(): ?LDClient
    {
        if ($this->client !== null) {
            return $this->client;
        }

        if ($this->clientUnavailable) {
            return null;
        }

        try {
            return $this->client = new LDClient($this->sdkKey, $this->options());
        } catch (\Throwable $e) {
            // Construction fails on a malformed configuration, or if the HTTP
            // client the default feature requester needs is missing. Neither
            // improves by being retried during this request.
            $this->clientUnavailable = true;
            $this->logger->error(
                'Could not build the LaunchDarkly client; serving hardcoded flag defaults',
                ['exception' => $e],
            );

            return null;
        }
    }

    /**
     * @return array<string, mixed>
     */
    private function options(): array
    {
        $options = [
            'logger' => $this->logger,
            'connect_timeout' => self::CONNECT_TIMEOUT_SECONDS,
            'timeout' => self::TIMEOUT_SECONDS,
        ];

        // Only set when configured, so the SDK keeps its own defaults
        // otherwise rather than being handed an empty string.
        if ($this->baseUri !== null) {
            $options['base_uri'] = $this->baseUri;
        }

        if ($this->eventsUri !== null) {
            $options['events_uri'] = $this->eventsUri;
        }

        if ($this->cache !== null) {
            $options['cache'] = $this->cache;
        }

        return $options;
    }

    /**
     * The request's actor as a single `user` context, which is the kind
     * `LDContext::builder()` assumes. `plan`, `country`, and `email` are custom
     * attributes, addressable in targeting rules under those names.
     *
     * Neither `set()` nor `build()` throws; an unusable context is reported by
     * the SDK at evaluation time and yields the default.
     */
    private function context(Actor $actor): LDContext
    {
        $builder = LDContext::builder($actor->key);
        $builder->set('plan', $actor->plan);
        $builder->set('country', $actor->country);

        if ($actor->email !== null) {
            $builder->set('email', $actor->email);
        }

        return $builder->build();
    }

    private function warnUnexpectedType(string $key, string $expected, mixed $value): void
    {
        $this->logger->warning(sprintf(
            'Flag "%s" returned %s where %s was expected; using the default',
            $key,
            get_debug_type($value),
            $expected,
        ));
    }
}
