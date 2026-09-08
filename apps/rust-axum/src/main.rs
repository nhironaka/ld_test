mod actor;
mod flags;

use std::sync::Arc;

use axum::extract::State;
use axum::http::{HeaderMap, StatusCode};
use axum::routing::{get, post};
use axum::{Json, Router};
use serde::{Deserialize, Serialize};
use tokio::net::TcpListener;
use tokio::signal;

use crate::actor::Actor;
use crate::flags::Flags;

#[derive(Clone)]
struct AppState {
    flags: Arc<Flags>,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "info".into()),
        )
        .init();

    let flags = Arc::new(Flags::initialize(std::env::var("LD_SDK_KEY").ok()).await?);
    let state = AppState {
        flags: Arc::clone(&flags),
    };

    let app = Router::new()
        .route("/health", get(health))
        .route("/api/storefront", get(storefront))
        .route("/api/cart/items", post(add_cart_item))
        .with_state(state);

    let addr = std::env::var("BIND_ADDR").unwrap_or_else(|_| "127.0.0.1:8080".to_owned());
    let listener = TcpListener::bind(&addr).await?;
    tracing::info!(%addr, "darkstore-api listening");

    axum::serve(listener, app)
        .with_graceful_shutdown(async {
            let _ = signal::ctrl_c().await;
        })
        .await?;

    flags.shutdown();
    Ok(())
}

async fn health() -> Json<serde_json::Value> {
    Json(serde_json::json!({ "status": "ok" }))
}

#[derive(Serialize)]
struct Storefront {
    banner: String,
    checkout: &'static str,
}

async fn storefront(State(state): State<AppState>, headers: HeaderMap) -> Json<Storefront> {
    let actor = Actor::from_headers(&headers);

    Json(Storefront {
        banner: state.flags.banner_copy(&actor),
        checkout: if state.flags.checkout_redesign(&actor) {
            "redesign"
        } else {
            "legacy"
        },
    })
}

#[derive(Deserialize)]
struct AddCartItem {
    #[serde(default = "one")]
    quantity: i64,
}

fn one() -> i64 {
    1
}

#[derive(Serialize)]
struct CartResponse {
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<&'static str>,
    #[serde(skip_serializing_if = "Option::is_none")]
    quantity: Option<i64>,
    limit: i64,
}

async fn add_cart_item(
    State(state): State<AppState>,
    headers: HeaderMap,
    Json(body): Json<AddCartItem>,
) -> (StatusCode, Json<CartResponse>) {
    let actor = Actor::from_headers(&headers);
    let limit = state.flags.max_cart_items(&actor);

    if body.quantity > limit {
        return (
            StatusCode::UNPROCESSABLE_ENTITY,
            Json(CartResponse {
                error: Some("cart_limit_exceeded"),
                quantity: None,
                limit,
            }),
        );
    }

    (
        StatusCode::CREATED,
        Json(CartResponse {
            error: None,
            quantity: Some(body.quantity),
            limit,
        }),
    )
}
