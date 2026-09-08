<?php

declare(strict_types=1);

use DarkStore\Support\Actor;
use DarkStore\Support\FeatureFlags;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Slim\App;

return static function (App $app, FeatureFlags $flags): void {
    $json = static function (ResponseInterface $response, array $payload, int $status = 200): ResponseInterface {
        $response->getBody()->write(json_encode($payload, JSON_THROW_ON_ERROR));

        return $response
            ->withHeader('Content-Type', 'application/json')
            ->withStatus($status);
    };

    $app->get('/health', static fn (
        ServerRequestInterface $request,
        ResponseInterface $response
    ): ResponseInterface => $json($response, ['status' => 'ok']));

    $app->get('/api/storefront', static function (
        ServerRequestInterface $request,
        ResponseInterface $response
    ) use ($flags, $json): ResponseInterface {
        $actor = Actor::fromRequest($request);

        return $json($response, [
            'banner' => $flags->bannerCopy($actor),
            'checkout' => $flags->checkoutRedesign($actor) ? 'redesign' : 'legacy',
        ]);
    });

    $app->post('/api/cart/items', static function (
        ServerRequestInterface $request,
        ResponseInterface $response
    ) use ($flags, $json): ResponseInterface {
        $actor = Actor::fromRequest($request);

        $body = (string) $request->getBody();
        $payload = $body === '' ? [] : json_decode($body, true, 512, JSON_THROW_ON_ERROR);
        $quantity = (int) ($payload['quantity'] ?? 1);
        $limit = $flags->maxCartItems($actor);

        if ($quantity > $limit) {
            return $json($response, ['error' => 'cart_limit_exceeded', 'limit' => $limit], 422);
        }

        return $json($response, ['quantity' => $quantity, 'limit' => $limit], 201);
    });
};
