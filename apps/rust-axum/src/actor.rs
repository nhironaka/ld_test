use axum::http::HeaderMap;

/// The caller, reduced to the attributes a targeting rule would plausibly
/// want. Built once per request from forwarded auth headers.
///
/// The fields are unread while `Flags` returns constants; drop the `allow`
/// once they feed a real evaluation context.
#[allow(dead_code)]
#[derive(Debug, Clone)]
pub struct Actor {
    pub key: String,
    pub email: Option<String>,
    pub plan: String,
    pub country: String,
}

impl Actor {
    pub fn from_headers(headers: &HeaderMap) -> Self {
        let get = |name: &str| {
            headers
                .get(name)
                .and_then(|v| v.to_str().ok())
                .map(str::to_owned)
        };

        Self {
            key: get("x-user-key").unwrap_or_else(|| "anonymous".to_owned()),
            email: get("x-user-email"),
            plan: get("x-user-plan").unwrap_or_else(|| "free".to_owned()),
            country: get("x-user-country").unwrap_or_else(|| "US".to_owned()),
        }
    }
}
