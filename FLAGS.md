# Flags used by the fixtures

## `apps/` — the server and Android fixtures

All five apps under `apps/` make the same three decisions, so one LaunchDarkly
project can back them all. Create these before running an install test if you
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

## The button-copy demos

`LDButtonDemo`, `experimentation`, and `android-button-demo` predate the
`apps/` fixtures and share a different, smaller flag set. They evaluate a
single string flag and fire a single conversion metric.

| Key | Type | Fallback in code | Purpose |
| --- | --- | --- | --- |
| `ld-example-button-copy` | string | `Get started` | The button's label. Each variation is a different label string. |
| `ld-example-button-clicked` | metric | — | Conversion metric fired on each tap. |

The evaluation subject is a single `user` context keyed by email, set in each
app's `Config` file. Fill in the mobile key there before expecting real values;
the committed sources carry `mob-YOUR-MOBILE-KEY`.
