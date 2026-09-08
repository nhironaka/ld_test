<?php

declare(strict_types=1);

namespace DarkStore\Support;

use Psr\Http\Message\ServerRequestInterface;

/**
 * The caller, reduced to the attributes a targeting rule would plausibly
 * want. Built once per request from forwarded auth headers.
 */
final readonly class Actor
{
    public function __construct(
        public string $key,
        public ?string $email,
        public string $plan,
        public string $country,
    ) {
    }

    public static function fromRequest(ServerRequestInterface $request): self
    {
        $header = static function (string $name, ?string $fallback) use ($request): ?string {
            $value = $request->getHeaderLine($name);

            return $value === '' ? $fallback : $value;
        };

        return new self(
            key: $header('X-User-Key', 'anonymous') ?? 'anonymous',
            email: $header('X-User-Email', null),
            plan: $header('X-User-Plan', 'free') ?? 'free',
            country: $header('X-User-Country', 'US') ?? 'US',
        );
    }
}
