import UIKit
import LaunchDarkly

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        startLaunchDarkly()

        let tabs = UITabBarController()
        tabs.viewControllers = [
            inNav(TrackOnlyViewController(),         title: "Track Only",  icon: "chart.bar"),
            inNav(FullExperimentationViewController(), title: "Full Exp",  icon: "flask"),
            inNav(ButtonCopyViewController(),         title: "Button Copy", icon: "hand.tap"),
        ]

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = tabs
        window?.makeKeyAndVisible()
        return true
    }

    private func inNav(_ vc: UIViewController, title: String, icon: String) -> UINavigationController {
        vc.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: icon), tag: 0)
        return UINavigationController(rootViewController: vc)
    }
}

// ── Snippet: track-only.snippet.md ── startLaunchDarkly() ──────────
// Lightly adapted: replaced "YOUR_MOBILE_KEY" with Config.mobileKey.
// Call this once from your app startup.
func startLaunchDarkly() {
    let config = LDConfig(mobileKey: Config.mobileKey, autoEnvAttributes: .enabled)
    var contextBuilder = LDContextBuilder(key: Config.userEmail)
    contextBuilder.kind("user")
    contextBuilder.trySetValue("email", .string(Config.userEmail))
    guard case .success(let context) = contextBuilder.build() else { return }

    LDClient.start(config: config, context: context, startWaitSeconds: 5) { timedOut in
        if timedOut {
            print("LD: SDK didn't initialize in 5 seconds. Still running.")
        } else {
            print("LD: SDK successfully initialized with the latest flags.")
        }
        NotificationCenter.default.post(name: .ldInitialized, object: nil)
    }
}

extension Notification.Name {
    static let ldInitialized    = Notification.Name("ldInitialized")
    static let ldVariantChanged = Notification.Name("ldVariantChanged")
}
