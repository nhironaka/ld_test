import UIKit
import LaunchDarkly

// Demonstrates: button-copy.snippet.md
//
// The button's title is driven by the string flag variation — each variation
// value is a different button label (e.g. "Get started", "Start for free").
// Tapping the button fires the experiment's conversion metric.
//
// NOTE: configureExperimentButton uses the legacy setTitle(_:for:) API.
// The demo button must NOT have a UIButton.Configuration applied — see below.
// This is a known limitation of the snippet; see bug notes in README.
class ButtonCopyViewController: UIViewController {

    // Use a plain UIButton without UIButton.Configuration.
    // configureExperimentButton calls setTitle(_:for:) which is silently
    // ignored on buttons that have a UIButton.Configuration set.
    private let experimentButton  = UIButton(type: .custom)
    private let reconfigureButton = UIButton(type: .system)
    private let tapCountLabel     = UILabel()
    private let noteLabel         = UILabel()
    private var tapCount          = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Button Copy"
        view.backgroundColor = .systemBackground
        setupUI()

        NotificationCenter.default.addObserver(
            self, selector: #selector(sdkReady), name: .ldInitialized, object: nil)
        // Wire the experiment button once the SDK is ready.
        if LDClient.get() != nil {
            configureExperimentButton(experimentButton) { [weak self] in self?.onExperimentTap() }
        }
    }

    private func setupUI() {
        // Style experimentButton without UIButton.Configuration so that
        // configureExperimentButton's setTitle(_:for:) call takes effect.
        experimentButton.backgroundColor = .systemGreen
        experimentButton.setTitle("Loading…", for: .normal)
        experimentButton.setTitleColor(.white, for: .normal)
        experimentButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        experimentButton.layer.cornerRadius = 10
        experimentButton.translatesAutoresizingMaskIntoConstraints = false

        var reCfg = UIButton.Configuration.tinted()
        reCfg.title = "Re-configure (simulate post-identify)"
        reconfigureButton.configuration = reCfg
        reconfigureButton.addTarget(self, action: #selector(reconfigureTapped), for: .touchUpInside)

        tapCountLabel.textAlignment = .center
        tapCountLabel.textColor = .secondaryLabel
        tapCountLabel.font = .preferredFont(forTextStyle: .callout)
        tapCountLabel.text = "Experiment taps: 0"

        noteLabel.text = """
            The green button's title comes from '\(Config.flagKey)'.
            Each variation value should be a label string.
            Tapping it tracks '\(Config.metricKey)'.
            """
        noteLabel.numberOfLines = 0
        noteLabel.textAlignment = .center
        noteLabel.textColor = .secondaryLabel
        noteLabel.font = .preferredFont(forTextStyle: .footnote)

        let stack = UIStackView(arrangedSubviews: [
            experimentButton, reconfigureButton, tapCountLabel, noteLabel,
        ])
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
        configureExperimentButton(experimentButton) { [weak self] in self?.onExperimentTap() }
    }

    @objc private func reconfigureTapped() {
        configureExperimentButton(experimentButton) { [weak self] in self?.onExperimentTap() }
    }

    private func onExperimentTap() {
        tapCount += 1
        tapCountLabel.text = "Experiment taps: \(tapCount)"
    }
}

// ── Snippet: button-copy.snippet.md ── configureExperimentButton() ──
// Lightly adapted: replaced "YOUR_FLAG_KEY"/"YOUR_METRIC_KEY" with Config values.
//
// Configures a UIButton to display the assigned variation's title and track taps.
// Pass your existing button instance to wire it up without changing your layout.
// Call this after startLaunchDarkly() and after identify() resolves (if the user
// became known mid-session).
//
// Prerequisites:
//   - A string flag whose key matches Config.flagKey. Set each variation's value to
//     the button label you want users to see (e.g. "Get started", "Start for free").
//     The flag value is used as the button title directly.
//   - A tap metric whose key matches Config.metricKey attached to your experiment.
// Requires iOS 14+. For iOS 13 support, replace UIAction with addTarget(_:action:for:).
@available(iOS 14.0, *)
func configureExperimentButton(_ button: UIButton, onTap: (() -> Void)? = nil) {
    let client = LDClient.get()!

    // The flag value is the button title. The default is shown when the flag is off
    // or the SDK hasn't finished initializing yet.
    // Don't cache the result — LaunchDarkly deduplicates exposure events automatically.
    let label = client.stringVariation(forKey: Config.flagKey, defaultValue: "Get started")
    // UIButton.Configuration (iOS 15+) ignores setTitle(_:for:). Detect and handle both.
    if #available(iOS 15, *), button.configuration != nil {
        button.configuration?.title = label
    } else {
        button.setTitle(label, for: .normal)
    }

    // Use a stable identifier so re-calling this function (e.g. after identify())
    // replaces the existing handler rather than stacking a second one.
    let actionID = UIAction.Identifier("com.example.experimentButton")
    button.removeAction(identifiedBy: actionID, for: .touchUpInside)

    let action = UIAction(identifier: actionID) { _ in
        // Track the tap so LaunchDarkly can attribute it to the right variation.
        // Use the same context that was active during the flag evaluation above —
        // mismatched contexts break conversion attribution.
        client.track(key: Config.metricKey)
        onTap?()
    }
    button.addAction(action, for: .touchUpInside)
}
