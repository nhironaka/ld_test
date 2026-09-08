<?php

declare(strict_types=1);

namespace DarkStore\Tests;

use PHPUnit\Framework\TestCase;
use Nyholm\Psr7\Factory\Psr17Factory;

final class StorefrontTest extends TestCase
{
    public function testStorefrontServesABannerAndCheckoutVariant(): void
    {
        $bootstrap = require __DIR__ . '/../src/bootstrap.php';
        $request = (new Psr17Factory())->createServerRequest('GET', '/api/storefront');

        $response = $bootstrap()->handle($request);
        $body = json_decode((string) $response->getBody(), true, 512, JSON_THROW_ON_ERROR);

        self::assertSame(200, $response->getStatusCode());
        self::assertNotEmpty($body['banner']);
        self::assertContains($body['checkout'], ['legacy', 'redesign']);
    }
}
