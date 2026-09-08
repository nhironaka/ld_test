import UIKit
import LaunchDarkly

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        startLaunchDarkly()

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UINavigationController(rootViewController: ViewController())
        window?.makeKeyAndVisible()
        return true
    }
}

// ── startLaunchDarkly() ─────────────────────────────────────────────────────
// Call once from application(_:didFinishLaunchingWithOptions:).
//
// The context identifies the current user to LaunchDarkly so targeting rules
// can assign them to the correct experiment variation. The key must be stable
// per user — using the email here keeps it readable for demos. In production,
// prefer an opaque ID that doesn't change if the user updates their email.
//
// autoEnvAttributes: .enabled automatically attaches device/OS metadata,
// which is useful for debugging but can be disabled in production if you
// prefer a minimal payload.
//
// startWaitSeconds: 5 blocks the completion handler for up to 5 seconds while
// the SDK fetches the latest flag values. The app posts .ldInitialized so any
// already-visible UI can re-evaluate flags once the SDK is ready.
func startLaunchDarkly() {
    let config = LDConfig(mobileKey: Config.mobileKey, autoEnvAttributes: .enabled)

    // Build a user context. The "Test users" targeting rule matches on the
    // email attribute — use an email that's in the rule's list.
    var contextBuilder = LDContextBuilder(key: "you@example.com")
    contextBuilder.kind("user")
    contextBuilder.trySetValue("email", .string("you@example.com"))
    guard case .success(let context) = contextBuilder.build() else { return }

    LDClient.start(config: config, context: context, startWaitSeconds: 5) { timedOut in
        if timedOut {
            // The SDK is still running and will update flags when they arrive.
            print("LD: SDK didn't initialize in 5 s — continuing.")
        } else {
            print("LD: SDK initialized.")
        }
        // Notify any waiting view controllers that flag values are available.
        NotificationCenter.default.post(name: .ldInitialized, object: nil)
    }
}

extension Notification.Name {
    static let ldInitialized = Notification.Name("ldInitialized")
}
