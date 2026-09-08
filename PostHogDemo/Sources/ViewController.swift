import UIKit
import PostHog

// Demonstrates a minimal PostHog button-copy experiment.
//
// Flow:
//   1. On load the button shows "Get started" (the default fallback value).
//   2. Once .phFlagsLoaded fires, updateButton() reads the multivariate string
//      flag and replaces the title with the assigned variation.
//   3. Each tap calls PostHogSDK.shared.capture(_:) to record the conversion
//      event, which PostHog uses to compute the experiment's conversion rate.
class ViewController: UIViewController {

    private let experimentButton = UIButton(type: .custom)
    private let tapCountLabel    = UILabel()
    private var tapCount         = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "PostHogDemo"
        view.backgroundColor = .systemBackground
        setupUI()

        NotificationCenter.default.addObserver(
            self, selector: #selector(flagsLoaded), name: .phFlagsLoaded, object: nil)

        // Fast path: flags may already be cached from a prior launch.
        updateButton()
    }

    private func setupUI() {
        experimentButton.backgroundColor = .systemIndigo
        experimentButton.setTitle("Get started", for: .normal)
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

    @objc private func flagsLoaded() {
        updateButton()
    }

    private func updateButton() {
        // getFeatureFlag returns Any? — cast to String for multivariate flags.
        // Falls back to "Get started" when the flag is off or not yet loaded.
        let label = PostHogSDK.shared.getFeatureFlag(Config.flagKey) as? String ?? "Get started"
        experimentButton.setTitle(label, for: .normal)

        // Stable action identifier prevents stacking duplicate handlers when
        // updateButton() is called more than once (e.g. after a flag reload).
        let actionID = UIAction.Identifier("com.launchdarkly.posthog.experimentButton")
        experimentButton.removeAction(identifiedBy: actionID, for: .touchUpInside)
        experimentButton.addAction(UIAction(identifier: actionID) { [weak self] _ in
            PostHogSDK.shared.capture(Config.eventKey)
            self?.tapCount += 1
            self?.tapCountLabel.text = "Taps: \(self?.tapCount ?? 0)"
        }, for: .touchUpInside)
    }
}
