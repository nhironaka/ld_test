<?php

declare(strict_types=1);

use DarkStore\Support\FeatureFlags;
use DarkStore\Support\StaticFeatureFlags;
use DI\ContainerBuilder;
use Slim\App;
use Slim\Factory\AppFactory;

return static function (): App {
    $builder = new ContainerBuilder();
    $builder->addDefinitions([
        FeatureFlags::class => static fn (): FeatureFlags => new StaticFeatureFlags(
            sdkKey: getenv('LD_SDK_KEY') ?: null,
        ),
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
