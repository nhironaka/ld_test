import UIKit
import LaunchDarkly

// Demonstrates: track-only.snippet.md
//
// Use case: you already have flag evaluation in place and just want to
// add conversion tracking. No flag variation is read here — you're only
// funneling a metric event into the LaunchDarkly experiment pipeline.
class TrackOnlyViewController: UIViewController {

    private let statusLabel  = UILabel()
    private let trackButton  = UIButton(type: .system)
    private let countLabel   = UILabel()
    private var trackCount   = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Track Only"
        view.backgroundColor = .systemBackground
        setupUI()
    }

    private func setupUI() {
        let stack = UIStackView(arrangedSubviews: [statusLabel, trackButton, countLabel])
        stack.axis = .vertical
        stack.spacing = 24
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        statusLabel.text = "Tap the button to fire a metric event.\n\nNo flag is read here — only tracking."
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.font = .preferredFont(forTextStyle: .body)

        var config = UIButton.Configuration.filled()
        config.title = "Track Metric Event"
        config.baseBackgroundColor = .systemBlue
        trackButton.configuration = config
        trackButton.addTarget(self, action: #selector(trackTapped), for: .touchUpInside)

        countLabel.textAlignment = .center
        countLabel.textColor = .secondaryLabel
        countLabel.font = .preferredFont(forTextStyle: .callout)
        countLabel.text = "Events sent: 0"

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
        ])
    }

    @objc private func trackTapped() {
        trackMetric(metricKey: Config.metricKey)
        trackCount += 1
        countLabel.text = "Events sent: \(trackCount)"
        statusLabel.text = "Tracked '\(Config.metricKey)' ✓"
    }
}

// ── Snippet: track-only.snippet.md ── trackMetric() ────────────────
// Verbatim except metricKey default removed (this file calls with Config.metricKey).
// Call trackMetric when a metric action occurs in your app —
// a tap, a form submit, a screen view, a custom event, whatever your metric measures.
func trackMetric(metricKey: String, data: LDValue = .null) {
    let client = LDClient.get()!
    client.track(key: metricKey, data: data)
}
