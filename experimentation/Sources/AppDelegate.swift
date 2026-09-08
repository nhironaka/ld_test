import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        startFeatureFlags()

        let tabs = UITabBarController()
        tabs.viewControllers = [
            inNav(TrackOnlyViewController(),           title: "Track Only",  icon: "chart.bar"),
            inNav(FullExperimentationViewController(), title: "Full Exp",    icon: "flask"),
            inNav(ButtonCopyViewController(),          title: "Button Copy", icon: "hand.tap"),
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

// ── startFeatureFlags() ────────────────────────────────────────────
// Call this once from your app startup.
//
// The user key identifies the current user so targeting rules can assign them
// to the correct experiment variation. It must be stable per user.
func startFeatureFlags() {
    Flags.configure(StaticFeatureFlags())
    Flags.shared.start(userKey: Config.userEmail, timeoutSeconds: 5)
}
