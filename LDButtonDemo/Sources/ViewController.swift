import UIKit

// Demonstrates a minimal button-copy experiment.
//
// Flow:
//   1. On load the button shows "Loading…" until flag values are available.
//   2. Once .flagsReady fires (or values are already available),
//      updateButton() reads the string flag and sets it as the button title.
//      An exposure is expected to be recorded at this point.
//   3. Each tap calls track(key:) to record a conversion event, which is what
//      an experiment's conversion rate is computed from.
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

        // Listen for the ready notification posted by startFeatureFlags().
        // This handles the normal startup path where values arrive after viewDidLoad.
        NotificationCenter.default.addObserver(
            self, selector: #selector(flagsReady), name: .flagsReady, object: nil)

        // Handle the fast path: values already available before this VC loaded
        // (e.g. the view is pushed after a tab switch).
        if Flags.shared.isReady {
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

    @objc private func flagsReady() {
        updateButton()
    }

    private func updateButton() {
        let flags = Flags.shared

        // Read the flag value — each variation is a different label string.
        // Don't cache the result; exposure events are expected to be deduplicated
        // for us, so re-evaluating every time is safe and picks up the latest value.
        let label = flags.stringVariation(forKey: Config.flagKey, defaultValue: "Get started")
        experimentButton.setTitle(label, for: .normal)

        // Use a stable action identifier so re-calling updateButton() (e.g. after identify())
        // replaces the existing handler rather than stacking a second one.
        let actionID = UIAction.Identifier("com.launchdarkly.experimentButton")
        experimentButton.removeAction(identifiedBy: actionID, for: .touchUpInside)
        experimentButton.addAction(UIAction(identifier: actionID) { [weak self] _ in
            // Track the conversion. This must be attributed to the same context that
            // was active during the flag evaluation above — mismatched contexts break
            // conversion attribution.
            flags.track(key: Config.metricKey)
            // Force-flush so events are delivered immediately during testing.
            // Remove this line before shipping to production.
            flags.flush()
            self?.tapCount += 1
            self?.tapCountLabel.text = "Taps: \(self?.tapCount ?? 0)"
        }, for: .touchUpInside)
    }
}
