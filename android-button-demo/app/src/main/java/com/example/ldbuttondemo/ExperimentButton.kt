package com.example.ldbuttondemo

import android.widget.Button
import com.launchdarkly.sdk.android.LDClient

// Configures a Button to display the assigned variation's label and track clicks.
// Pass your existing button instance to wire it up without changing your layout.
// Call this after LDClient.init() and after identify() resolves (if the user
// became known mid-session).
//
// Prerequisites:
//   - A string flag whose key matches ld-example-button-copy. Set each variation's value to
//     the button label you want users to see (e.g. "Get started", "Start for free").
//     The flag value is used as the button label directly.
//   - A click metric whose key matches ld-example-button-clicked attached to your experiment.
fun configureExperimentButton(button: Button, onClick: (() -> Unit)? = null) {
    val client = LDClient.get() ?: return

    // The flag value is the button label. The default is shown when the flag is off
    // or the SDK hasn't finished initializing yet.
    // Don't cache the result — LaunchDarkly deduplicates exposure events automatically.
    button.text = client.stringVariation("ld-example-button-copy", "Get started")

    button.setOnClickListener {
        // Track the click so LaunchDarkly can attribute it to the right variation.
        // Use the same context that was active during the flag evaluation above —
        // mismatched contexts break conversion attribution.
        client.track("ld-example-button-clicked")
        onClick?.invoke()
    }
}
