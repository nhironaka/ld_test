import Foundation

/// Central seam for every runtime feature decision in the app.
///
/// Today `stringVariation` hands back the caller's own fallback and `track`
/// drops the event on the floor. The intent is for both to talk to a remote
/// flag evaluation service, so an experience can be varied — and the resulting
/// conversion measured — without shipping a release.
///
/// Four things any implementation has to honour:
///  - `start` is called from `application(_:didFinishLaunchingWithOptions:)`
///    and must not block the main thread waiting for a first payload. It posts
///    `.flagsReady` once values are available, because view controllers may
///    already be on screen by then.
///  - `identify` is called when an anonymous user becomes known (login).
///    Evaluations after it completes are expected to return values for the new
///    context, which is why it takes a completion handler rather than
///    returning immediately.
///  - `stringVariation` is expected to record an exposure, so call sites
///    deliberately re-evaluate instead of caching the result.
///  - `track` has to be attributed to the same context that was active during
///    the matching `stringVariation` call, or the conversion data is
///    meaningless.
protocol FeatureFlags: AnyObject {
    /// Whether flag values are available yet. Call sites use this for the fast
    /// path where a view loads after startup already finished.
    var isReady: Bool { get }

    func start(userKey: String, timeoutSeconds: TimeInterval)

    func identify(userKey: String, completion: @escaping () -> Void)

    func stringVariation(forKey key: String, defaultValue: String) -> String

    func track(key: String, data: [String: Any]?)

    /// Force-flushes buffered events. Useful while testing; a real app leaves
    /// the default batching alone.
    func flush()
}

extension FeatureFlags {
    func track(key: String) {
        track(key: key, data: nil)
    }
}

/// Hardcoded defaults: every evaluation returns the caller's fallback, every
/// event is dropped.
final class StaticFeatureFlags: FeatureFlags {

    var isReady: Bool { true }

    func start(userKey: String, timeoutSeconds: TimeInterval) {
        print("Flags: no evaluation service configured — serving caller defaults.")
        NotificationCenter.default.post(name: .flagsReady, object: nil)
    }

    func identify(userKey: String, completion: @escaping () -> Void) {
        completion()
    }

    func stringVariation(forKey key: String, defaultValue: String) -> String {
        defaultValue
    }

    func track(key: String, data: [String: Any]?) {}

    func flush() {}
}

/// The process-wide instance, assigned once during startup.
enum Flags {
    static private(set) var shared: FeatureFlags = StaticFeatureFlags()

    static func configure(_ flags: FeatureFlags) {
        shared = flags
    }
}

extension Notification.Name {
    /// Posted once flag values are available.
    static let flagsReady = Notification.Name("flagsReady")
    /// Posted by applyVariant() when the active variation changes.
    static let variantChanged = Notification.Name("variantChanged")
}
