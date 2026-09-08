import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        startFeatureFlags()

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UINavigationController(rootViewController: ViewController())
        window?.makeKeyAndVisible()
        return true
    }
}

// ── startFeatureFlags() ─────────────────────────────────────────────────────
// Call once from application(_:didFinishLaunchingWithOptions:).
//
// The user key identifies the current user so targeting rules can assign them
// to the correct experiment variation. The key must be stable per user — using
// the email here keeps it readable for demos. In production, prefer an opaque
// ID that doesn't change if the user updates their email.
//
// The timeout bounds how long startup will wait for the first set of flag
// values. Whatever backs Flags.shared posts .flagsReady when values arrive, so
// any already-visible UI can re-evaluate.
func startFeatureFlags() {
    Flags.configure(StaticFeatureFlags())
    Flags.shared.start(userKey: Config.userKey, timeoutSeconds: 5)
}
