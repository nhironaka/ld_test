# Flags used by every app

All five apps make the same three decisions, so one LaunchDarkly project can
back the whole monorepo. Create these before running an install test if you
want to see real values come back.

| Key | Type | Fallback in code | Purpose |
| --- | --- | --- | --- |
| `checkout-redesign` | boolean | `false` | Gates the rebuilt checkout funnel. |
| `banner-copy` | string | `Free shipping on orders over $50` | Storefront banner text. |
| `max-cart-items` | number | `25` | Per-plan cart ceiling. |

Every app builds an evaluation subject with the same four attributes, read
from `X-User-*` request headers on the servers and from the signed-in shopper
on Android:

| Attribute | Example |
| --- | --- |
| key | `user-1` (or `anonymous`) |
| email | `shopper@example.com` |
| plan | `free`, `pro` |
| country | `US` |
