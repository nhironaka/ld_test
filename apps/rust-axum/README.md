# rust-axum

Axum 0.8 storefront API on Tokio.

```sh
cargo run           # http://localhost:8080
cargo clippy --all-targets
```

All feature decisions live in `src/flags.rs`. `Flags` is built once in `main`
and shared across handlers via `Arc`.
