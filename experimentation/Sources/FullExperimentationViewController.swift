import UIKit

// Demonstrates: full.snippet.md
//
// Shows the three-step experimentation lifecycle:
//  1. Flags are already started by AppDelegate (startFeatureFlags).
//  2. "Identify User" simulates a login — calls onUserBecomesEligible
//     which identifies the new context and evaluates the flag.
//  3. "Track Conversion" fires the metric event for the active variant.
class FullExperimentationViewController: UIViewController {

    private let variantBadge    = UILabel()
    private let identifyButton  = UIButton(type: .system)
    private let trackButton     = UIButton(type: .system)
    private let logView         = UITextView()
    private var currentVariant  = "control"

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Full Experimentation"
        view.backgroundColor = .systemBackground
        setupUI()
        NotificationCenter.default.addObserver(
            self, selector: #selector(flagsReady), name: .flagsReady, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(variantChanged(_:)), name: .variantChanged, object: nil)
    }

    private func setupUI() {
        variantBadge.text = "variant: —"
        variantBadge.font = .monospacedSystemFont(ofSize: 18, weight: .semibold)
        variantBadge.textAlignment = .center

        var idCfg = UIButton.Configuration.filled()
        idCfg.title = "Identify User & Evaluate Flag"
        idCfg.baseBackgroundColor = .systemIndigo
        identifyButton.configuration = idCfg
        identifyButton.addTarget(self, action: #selector(identifyTapped), for: .touchUpInside)

        var trackCfg = UIButton.Configuration.tinted()
        trackCfg.title = "Track Conversion Metric"
        trackButton.configuration = trackCfg
        trackButton.addTarget(self, action: #selector(trackConversionTapped), for: .touchUpInside)

        logView.isEditable = false
        logView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        logView.backgroundColor = .secondarySystemBackground
        logView.layer.cornerRadius = 8
        logView.text = "Log output will appear here.\n"

        let stack = UIStackView(arrangedSubviews: [variantBadge, identifyButton, trackButton, logView])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            logView.heightAnchor.constraint(greaterThanOrEqualToConstant: 180),
        ])
    }

    // MARK: - Actions

    @objc private func identifyTapped() {
        log("→ identify(\(Config.userEmail))")
        onUserBecomesEligible(finalUserKey: Config.userEmail)
        Flags.shared.flush()
        log("→ flush()")
    }

    @objc private func trackConversionTapped() {
        // Mirrors the trackMetric helper from full.snippet.md.
        let flags = Flags.shared
        guard flags.isReady else {
            log("⚠ flags not ready — tap Identify first")
            return
        }
        flags.track(key: Config.metricKey)
        log("→ track('\(Config.metricKey)') for variant '\(currentVariant)'")
        flags.flush()
        log("→ flush()")
    }

    @objc private func flagsReady() {
        log("✓ flags ready")
    }

    @objc private func variantChanged(_ note: Notification) {
        guard let variant = note.userInfo?["variant"] as? String else { return }
        currentVariant = variant
        variantBadge.text = "variant: \(variant)"
        log("✓ variant = '\(variant)'")
    }

    private func log(_ msg: String) {
        DispatchQueue.main.async {
            self.logView.text += msg + "\n"
            let bottom = NSRange(location: self.logView.text.utf16.count - 1, length: 1)
            self.logView.scrollRangeToVisible(bottom)
        }
    }
}

// ── Snippet: full.snippet.md ── onUserBecomesEligible() ────────────
// Lightly adapted:
//   • replaced "YOUR_FLAG_KEY" with Config.flagKey
//   • applyVariant() posts a Notification so the VC can update its UI
//     (in a real app, applyVariant would directly update your view layer)
func onUserBecomesEligible(finalUserKey: String) {
    let flags = Flags.shared

    // Switch to the final context used for experiment eligibility. Use the
    // logged-in user's ID so experiment assignment stays consistent.
    flags.identify(userKey: finalUserKey) {
        // Evaluate the experiment flag where the user encounters the experience,
        // after identify completes.
        let variant = flags.stringVariation(forKey: Config.flagKey, defaultValue: "control")
        applyVariant(variant)
    }
}

// applyVariant is user-defined — implement it to apply the variation to your UI.
// In this demo we route it through NotificationCenter so the VC updates itself.
func applyVariant(_ variant: String) {
    DispatchQueue.main.async {
        NotificationCenter.default.post(
            name: .variantChanged,
            object: nil,
            userInfo: ["variant": variant]
        )
    }
}
