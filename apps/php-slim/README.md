# php-slim

Slim 4 storefront API, Composer-managed, PSR-4 autoloaded under `DarkStore\`.

```sh
composer install
composer serve       # http://localhost:8000
composer test
```

All feature decisions go through the `FeatureFlags` interface
(`src/Support/FeatureFlags.php`), bound in the container in
`src/bootstrap.php`. `StaticFeatureFlags` is the current hardcoded
implementation.
