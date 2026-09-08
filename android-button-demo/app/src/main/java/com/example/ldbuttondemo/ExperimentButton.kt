package com.example.ldbuttondemo

import android.widget.Button

// Configures a Button to display the assigned variation's label and track clicks.
// Pass your existing button instance to wire it up without changing your layout.
// Call this after FeatureFlags.init() resolves and after identify() resolves (if
// the user became known mid-session).
//
// Prerequisites:
//   - A string flag whose key matches ld-example-button-copy. Set each variation's value to
//     the button label you want users to see (e.g. "Get started", "Start for free").
//     The flag value is used as the button label directly.
//   - A click metric whose key matches ld-example-button-clicked attached to your experiment.
fun configureExperimentButton(flags: FeatureFlags, button: Button, onClick: (() -> Unit)? = null) {
    // The flag value is the button label. The default is shown when the flag is off
    // or values haven't arrived yet.
    // Don't cache the result — exposure events are expected to be deduplicated for us.
    button.text = flags.stringVariation("ld-example-button-copy", "Get started")

    button.setOnClickListener {
        // Track the click so it can be attributed to the right variation.
        // This must use the same context that was active during the flag evaluation
        // above — mismatched contexts break conversion attribution.
        flags.track("ld-example-button-clicked")
        onClick?.invoke()
    }
}
