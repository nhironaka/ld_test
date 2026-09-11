<?php

declare(strict_types=1);

use DarkStore\Support\FeatureFlags;
use DarkStore\Support\LaunchDarklyFeatureFlags;
use DarkStore\Support\StaticFeatureFlags;
use DI\ContainerBuilder;
use Monolog\Handler\ErrorLogHandler;
use Monolog\Logger;
use Slim\App;
use Slim\Factory\AppFactory;

return static function (): App {
    $builder = new ContainerBuilder();
    $builder->addDefinitions([
        FeatureFlags::class => static function (): FeatureFlags {
            // Both implementations log; without this the "no SDK key" and
            // "cannot reach LaunchDarkly" paths were silent. ErrorLogHandler
            // writes to error_log, which is where the rest of the app's
            // warnings already go.
            $logger = new Logger('darkstore', [new ErrorLogHandler()]);
            $sdkKey = getenv('LD_SDK_KEY') ?: null;

            if ($sdkKey === null) {
                return new StaticFeatureFlags(sdkKey: null, logger: $logger);
            }

            return new LaunchDarklyFeatureFlags(
                sdkKey: $sdkKey,
                logger: $logger,
                // Set both to a Relay Proxy to keep flag reads and event
                // delivery inside your own network; unset, the SDK talks to
                // LaunchDarkly directly.
                baseUri: getenv('LD_BASE_URI') ?: null,
                eventsUri: getenv('LD_EVENTS_URI') ?: null,
            );
        },
    ]);

    $container = $builder->build();
    AppFactory::setContainer($container);
    $app = AppFactory::create();
    $app->addBodyParsingMiddleware();
    $app->addRoutingMiddleware();
    $app->addErrorMiddleware(
        displayErrorDetails: (getenv('APP_ENV') ?: 'production') !== 'production',
        logErrors: true,
        logErrorDetails: true,
    );

    (require __DIR__ . '/routes.php')($app, $container->get(FeatureFlags::class));

    return $app;
};
