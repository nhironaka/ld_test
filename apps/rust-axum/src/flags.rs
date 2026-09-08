use crate::actor::Actor;

/// Central seam for every runtime feature decision in the service.
///
/// Today each method returns a hardcoded constant. The intent is for them to
/// consult a remote flag evaluation service, keyed off the current request's
/// actor, so we can roll changes out gradually instead of shipping a deploy
/// per toggle.
///
/// `Flags` is constructed once at startup and shared via `Arc`, so whatever
/// backs it must be `Send + Sync` and cheap to call per request.
pub struct Flags {
    #[allow(dead_code)]
    sdk_key: Option<String>,
}

impl Flags {
    /// Runs once during startup. A real evaluation client would connect here
    /// and wait for its initial payload before the server binds a port.
    pub async fn initialize(sdk_key: Option<String>) -> anyhow::Result<Self> {
        if sdk_key.is_none() {
            tracing::warn!("LD_SDK_KEY unset; serving hardcoded flag defaults");
        }

        Ok(Self { sdk_key })
    }

    /// Boolean rollout: gates the rebuilt checkout funnel.
    pub fn checkout_redesign(&self, _actor: &Actor) -> bool {
        false
    }

    /// String variation: marketing copy for the storefront banner.
    pub fn banner_copy(&self, _actor: &Actor) -> String {
        "Free shipping on orders over $50".to_owned()
    }

    /// Numeric variation: per-plan cart ceiling.
    pub fn max_cart_items(&self, _actor: &Actor) -> i64 {
        25
    }

    /// Called on graceful shutdown so any buffered analytics are flushed
    /// before the process exits.
    pub fn shutdown(&self) {}
}
