// Edit these values before running the app.
//
// apiKey:   Project Settings › Project API Key in your PostHog dashboard
// host:     Your PostHog instance URL (US cloud: https://us.i.posthog.com)
// flagKey:  Key of a multivariate string flag whose variations are button label strings
// eventKey: Name of the conversion event tracked on each button tap
enum Config {
    static let apiKey   = "phc_YOUR_PROJECT_API_KEY"
    static let host     = "https://us.i.posthog.com"
    static let flagKey  = "first-flag"
    static let eventKey = "button_tapped"
}
