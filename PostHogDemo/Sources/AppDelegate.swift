import UIKit
import PostHog

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        startPostHog()

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UINavigationController(rootViewController: ViewController())
        window?.makeKeyAndVisible()
        return true
    }
}

// Call once from application(_:didFinishLaunchingWithOptions:).
//
// identify() ties all subsequent events to a stable user identity so PostHog
// can attribute button taps to the correct person/session in the dashboard.
//
// reloadFeatureFlags fetches the latest flag assignments for this user and
// posts .phFlagsLoaded so any already-visible UI can react once they arrive.
func startPostHog() {
    let config = PostHogConfig(apiKey: Config.apiKey, host: Config.host)
    PostHogSDK.shared.setup(config)

    PostHogSDK.shared.identify("oero@gmail.com", userProperties: [
        "email": "oero@gmail.com",
    ])

    PostHogSDK.shared.reloadFeatureFlags {
        NotificationCenter.default.post(name: .phFlagsLoaded, object: nil)
    }
}

extension Notification.Name {
    static let phFlagsLoaded = Notification.Name("phFlagsLoaded")
}
