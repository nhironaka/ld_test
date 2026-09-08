// Edit these values before running the app.
// All three are required for the full demo; mobileKey alone is enough to test track-only.
//
// mobileKey:  Account Settings > Projects > [project] > [environment] — "Mobile key"
// flagKey:    Key of a string flag whose variations are the button label strings
//             (e.g. "Get started", "Start for free"). Must be in the same environment.
// metricKey:  Key of the conversion metric attached to your experiment.
// userEmail:  Email used as the evaluation context key.
enum Config {
    static let mobileKey  = "mob-YOUR-MOBILE-KEY"
    static let flagKey    = "ld-example-button-copy"
    static let metricKey  = "ld-example-button-clicked"
    static let userEmail  = "you@example.com"
}
