// Edit these values before running the app.
//
// mobileKey:  Account Settings › Projects › [project] › [environment] — "Mobile key"
// flagKey:    Key of a string flag whose variations are the button label strings
//             (e.g. "Get started", "Start for free"). Must be in the same environment.
// metricKey:  Key of the conversion metric attached to your experiment.
// userKey:    Stable per-user identifier used as the evaluation context key.
enum Config {
    static let mobileKey = "mob-YOUR-MOBILE-KEY"
    static let flagKey   = "ld-example-button-copy"
    static let metricKey = "ld-example-button-clicked"
    static let userKey   = "you@example.com"
}
