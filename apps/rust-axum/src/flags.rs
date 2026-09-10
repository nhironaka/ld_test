use std::time::Duration;

use launchdarkly_server_sdk::{Client, ConfigBuilder, Context, ContextBuilder};

use crate::actor::Actor;

/// Flag keys as they are defined in LaunchDarkly.
const CHECKOUT_REDESIGN_KEY: &str = "checkout-redesign";
const BANNER_COPY_KEY: &str = "banner-copy";
const MAX_CART_ITEMS_KEY: &str = "max-cart-items";

/// What each decision resolved to before the SDK was installed. These are
/// passed as the default on every evaluation, so a missing flag, a variation of
/// the wrong type, or an unreachable LaunchDarkly all degrade to the behaviour
/// this service already had rather than failing the request.
const CHECKOUT_REDESIGN_DEFAULT: bool = false;
const BANNER_COPY_DEFAULT: &str = "Free shipping on orders over $50";
const MAX_CART_ITEMS_DEFAULT: i64 = 25;

/// How long startup waits for the initial flag payload before serving defaults.
const START_WAIT: Duration = Duration::from_secs(5);

/// Central seam for every runtime feature decision in the service.
///
/// Each method asks LaunchDarkly for the current value, keyed off the actor the
/// call site passes in. Evaluation is a lookup against the in-memory store the
/// client keeps up to date over its streaming connection, so it costs no
/// network round trip on the request path.
///
/// `Flags` is constructed once at startup and shared via `Arc`. The client is
/// `Send + Sync` and expects to be a single instance per process, which is
/// exactly how it is held here.
pub struct Flags {
    /// `None` when `LD_SDK_KEY` is unset, in which case every method below
    /// returns its hardcoded default and no client is ever constructed. That
    /// keeps local runs working offline.
    client: Option<Client>,
}

impl Flags {
    /// Runs once during startup, before the server binds a port, so the
    /// client's connect-and-wait is not paid by a customer request.
    pub async fn initialize(sdk_key: Option<String>) -> anyhow::Result<Self> {
        let Some(sdk_key) = sdk_key.filter(|key| !key.trim().is_empty()) else {
            tracing::warn!("LD_SDK_KEY unset; serving hardcoded flag defaults");
            return Ok(Self { client: None });
        };

        let client = Client::build(ConfigBuilder::new(&sdk_key).build()?)?;
        client.start_with_default_executor();

        // `Some(false)` is a failed connection and `None` is the timeout
        // elapsing; neither is fatal, because every evaluation carries its own
        // default and the client keeps retrying in the background.
        if client.wait_for_initialization(START_WAIT).await != Some(true) {
            tracing::warn!(
                timeout_secs = START_WAIT.as_secs(),
                "LaunchDarkly did not connect in time; serving flag defaults until it does"
            );
        }

        Ok(Self {
            client: Some(client),
        })
    }

    /// Boolean rollout: gates the rebuilt checkout funnel.
    pub fn checkout_redesign(&self, actor: &Actor) -> bool {
        match self.target(actor) {
            Some((client, context)) => {
                client.bool_variation(&context, CHECKOUT_REDESIGN_KEY, CHECKOUT_REDESIGN_DEFAULT)
            }
            None => CHECKOUT_REDESIGN_DEFAULT,
        }
    }

    /// String variation: marketing copy for the storefront banner.
    pub fn banner_copy(&self, actor: &Actor) -> String {
        match self.target(actor) {
            Some((client, context)) => {
                client.str_variation(&context, BANNER_COPY_KEY, BANNER_COPY_DEFAULT.to_owned())
            }
            None => BANNER_COPY_DEFAULT.to_owned(),
        }
    }

    /// Numeric variation: per-plan cart ceiling.
    pub fn max_cart_items(&self, actor: &Actor) -> i64 {
        match self.target(actor) {
            Some((client, context)) => {
                client.int_variation(&context, MAX_CART_ITEMS_KEY, MAX_CART_ITEMS_DEFAULT)
            }
            None => MAX_CART_ITEMS_DEFAULT,
        }
    }

    /// Called on graceful shutdown so any buffered analytics are flushed
    /// before the process exits. `close` blocks until pending events have been
    /// delivered, which is safe here because it runs after the server has
    /// stopped accepting connections.
    pub fn shutdown(&self) {
        if let Some(client) = &self.client {
            client.close();
        }
    }

    /// Pairs the client with a context for this actor, or `None` when there is
    /// no client or the actor cannot be expressed as one, so the caller falls
    /// back to its default.
    fn target(&self, actor: &Actor) -> Option<(&Client, Context)> {
        let client = self.client.as_ref()?;

        match Self::context_for(actor) {
            Ok(context) => Some((client, context)),
            Err(error) => {
                tracing::error!(
                    %error,
                    "Could not build an evaluation context; serving flag defaults"
                );
                None
            }
        }
    }

    /// The request's actor as a single `user` context. `email` is a built-in
    /// attribute; `plan` and `country` are custom ones, and targeting rules
    /// address them by those names.
    fn context_for(actor: &Actor) -> Result<Context, String> {
        let mut builder = ContextBuilder::new(&actor.key);
        builder
            .kind("user")
            .set_string("plan", actor.plan.as_str())
            .set_string("country", actor.country.as_str());

        if let Some(email) = &actor.email {
            builder.set_string("email", email.as_str());
        }

        builder.build()
    }
}
