# rust-axum

Axum 0.8 storefront API on Tokio.

```sh
cargo run           # http://localhost:8080
cargo clippy --all-targets
```

All feature decisions live in `src/flags.rs`. `Flags` is built once in `main`
and shared across handlers via `Arc`.

## LaunchDarkly

`src/flags.rs` evaluates `checkout-redesign`, `banner-copy`, and
`max-cart-items` through `launchdarkly-server-sdk`, using a `user` context built
from the `X-User-*` headers `Actor` already reads. `email` maps onto the built-in
attribute of that name; `plan` and `country` are custom attributes, addressable
in targeting rules as-is.

```sh
LD_SDK_KEY=sdk-... cargo run
```

Without `LD_SDK_KEY` no client is ever constructed and every method returns the
same hardcoded constant it returned before, so local runs work offline. Those
constants are also the default passed on every evaluation, so an unreachable
LaunchDarkly, a missing flag, or a variation of the wrong type degrades to this
service's previous behaviour rather than failing the request.

The client is built in `main` before the listener binds, and startup waits up to
five seconds for the first flag payload, so no customer request pays for the
connect. Evaluation is then a lookup against the in-memory store the client
keeps current over its streaming connection, so it costs no network round trip.
Graceful shutdown calls `Flags::shutdown`, which closes the client and blocks
until buffered analytics events have been delivered.

SDK logs go through the `log` crate, which `tracing-subscriber` bridges into this
service's own output, so `RUST_LOG=info` shows connection state next to the
app's own events without extra wiring.

The SDK sets the floor for the toolchain: `launchdarkly-server-sdk` 3.2 declares
an MSRV of 1.95, so `rust-version` in `Cargo.toml` moved from `1.75` to `1.95`.
`rust-toolchain.toml` already pins `stable`, so nothing about how this app is
built changes.
