import UIKit
import LaunchDarkly

// Demonstrates a minimal LaunchDarkly button-copy experiment.
//
// Flow:
//   1. On load the button shows "Loading…" until the SDK is ready.
//   2. Once .ldInitialized fires (or the client is already available),
//      updateButton() reads the string flag and sets it as the button title.
//      LaunchDarkly records an exposure event automatically at this point.
//   3. Each tap calls client.track(key:) to record a conversion event,
//      which LaunchDarkly uses to compute the experiment's conversion rate.
class ViewController: UIViewController {

    // Use .custom (not a UIButton.Configuration) so that setTitle(_:for:)
    // works reliably. Configuration-based buttons silently ignore setTitle.
    private let experimentButton = UIButton(type: .custom)
    private let tapCountLabel    = UILabel()
    private var tapCount         = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "LDButtonDemo"
        view.backgroundColor = .systemBackground
        setupUI()

        // Listen for the SDK-ready notification posted by startLaunchDarkly().
        // This handles the normal startup path where the SDK finishes after viewDidLoad.
        NotificationCenter.default.addObserver(
            self, selector: #selector(sdkReady), name: .ldInitialized, object: nil)

        // Handle the fast path: SDK already initialized before this VC loaded
        // (e.g. the view is pushed after a tab switch).
        if LDClient.get() != nil {
            updateButton()
        }
    }

    private func setupUI() {
        experimentButton.backgroundColor = .systemBlue
        experimentButton.setTitle("Loading…", for: .normal)
        experimentButton.setTitleColor(.white, for: .normal)
        experimentButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        experimentButton.layer.cornerRadius = 12

        tapCountLabel.textAlignment = .center
        tapCountLabel.textColor = .secondaryLabel
        tapCountLabel.font = .preferredFont(forTextStyle: .callout)
        tapCountLabel.text = "Taps: 0"

        let stack = UIStackView(arrangedSubviews: [experimentButton, tapCountLabel])
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            experimentButton.heightAnchor.constraint(equalToConstant: 52),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
        ])
    }

    @objc private func sdkReady() {
        updateButton()
    }

    private func updateButton() {
        guard let client = LDClient.get() else { return }

        // Read the flag value — each variation is a different label string.
        // Don't cache the result; LaunchDarkly deduplicates exposure events automatically,
        // so calling stringVariation every time is safe and ensures the latest value.
        let label = client.stringVariation(forKey: Config.flagKey, defaultValue: "Get started")
        experimentButton.setTitle(label, for: .normal)

        // Use a stable action identifier so re-calling updateButton() (e.g. after identify())
        // replaces the existing handler rather than stacking a second one.
        let actionID = UIAction.Identifier("com.launchdarkly.experimentButton")
        experimentButton.removeAction(identifiedBy: actionID, for: .touchUpInside)
        experimentButton.addAction(UIAction(identifier: actionID) { [weak self] _ in
            // Track the conversion. Use the same client that was active during flag evaluation
            // above — mismatched contexts break conversion attribution.
            client.track(key: Config.metricKey)
            // Force-flush so events reach LaunchDarkly immediately during testing.
            // Remove this line before shipping to production.
            client.flush()
            self?.tapCount += 1
            self?.tapCountLabel.text = "Taps: \(self?.tapCount ?? 0)"
        }, for: .touchUpInside)
    }
}
