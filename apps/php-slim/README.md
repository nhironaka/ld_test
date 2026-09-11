# php-slim

Slim 4 storefront API, Composer-managed, PSR-4 autoloaded under `DarkStore\`.

```sh
composer install
composer serve       # http://localhost:8000
composer test
```

All feature decisions go through the `FeatureFlags` interface
(`src/Support/FeatureFlags.php`), bound in the container in
`src/bootstrap.php`. `StaticFeatureFlags` serves hardcoded values;
`LaunchDarklyFeatureFlags` evaluates them for real.

## LaunchDarkly

`src/Support/LaunchDarklyFeatureFlags.php` evaluates `checkout-redesign`,
`banner-copy`, and `max-cart-items` through `launchdarkly/server-sdk`, using a
`user` context built from the `X-User-*` headers `src/Support/Actor.php` already
reads. `plan`, `country`, and `email` are custom attributes, addressable in
targeting rules under those names.

```sh
LD_SDK_KEY=sdk-... composer serve
```

`src/bootstrap.php` binds the LaunchDarkly implementation only when `LD_SDK_KEY`
is set, and keeps `StaticFeatureFlags` otherwise, so tests and local runs work
offline. The flag keys and the values served when LaunchDarkly cannot answer
live in `FeatureFlagKeys` and `FeatureFlagDefaults`, which both implementations
read, so the fallbacks are defined once. Those fallbacks are what this service
returned before the SDK was installed, and they apply on every failure the SDK
can have: no key, unreachable LaunchDarkly, missing flag, or a variation of the
wrong type. In each case the response is unchanged and the reason is logged.

The client is built on the first evaluation that needs one, so a request that
reads no flag — `/health` — does no network I/O, and a broken configuration
costs one attempt per request rather than one per evaluation.

### The per-request cost

PHP has no long-lived process, so there is no streaming connection to hold and
no flag store that survives a request. The PHP SDK is built for that: **each
evaluation fetches the one flag it needs over HTTP**, so `/api/storefront`, which
reads two flags, makes two requests to LaunchDarkly. `CONNECT_TIMEOUT_SECONDS`
and `TIMEOUT_SECONDS` in `LaunchDarklyFeatureFlags` bound what that can cost a
customer when LaunchDarkly is slow or unreachable; they are 1s and 2s here
rather than the SDK's 3s defaults, because this service would rather serve a
slightly stale banner than hold a storefront request open.

Removing the round trips is a deployment change, not a code change. Either:

- **Run a [Relay Proxy](https://docs.launchdarkly.com/home/relay-proxy)
  alongside the app** and point `LD_BASE_URI` and `LD_EVENTS_URI` at it, so flag
  reads and event delivery stay inside your network.
- **Give the SDK a cache that outlives the request.** The constructor takes an
  optional PSR-6 `CacheItemPoolInterface`; pass one backed by APCu, the
  filesystem, or Redis and the SDK's HTTP cache revalidates instead of
  refetching. `src/bootstrap.php` passes none today, so the default in-memory
  cache is discarded with the process.

Analytics events are queued during the request and handed to a backgrounded
`curl`, so delivery does not delay the response.
