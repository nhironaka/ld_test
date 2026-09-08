package com.example.darkstore

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

/**
 * Re-identifies the flag client off the main thread. Extracted so the call
 * site in the ViewModel stays a single expression.
 */
internal fun CoroutineScope.launchIdentify(featureFlags: FeatureFlags, actor: Actor) {
    launch { featureFlags.identify(actor) }
}
