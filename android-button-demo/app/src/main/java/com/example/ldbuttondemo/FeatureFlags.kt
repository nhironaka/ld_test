package com.example.ldbuttondemo

import android.app.Application
import java.util.concurrent.Future
import java.util.concurrent.TimeUnit

/**
 * Central seam for every runtime feature decision in the app.
 *
 * Today [stringVariation] hands back the caller's own fallback and [track]
 * drops the event on the floor. The intent is for both to talk to a remote
 * flag evaluation service, so button copy can be changed — and the resulting
 * conversion measured — without shipping a release.
 *
 * Four things any implementation has to honour:
 *  - [init] is called from `Application.onCreate` and must not block the main
 *    thread. It returns a [Future] so callers can await the first payload off
 *    the main thread, which is what `MainActivity` does.
 *  - [identify] is called when an anonymous user becomes known (login).
 *    Evaluations after it are expected to return values for the new context.
 *  - [stringVariation] is expected to record an exposure, so call sites
 *    deliberately re-evaluate instead of caching the result.
 *  - [track] has to be attributed to the same context that was active during
 *    the matching [stringVariation] call, or the conversion data is
 *    meaningless.
 */
interface FeatureFlags {

    fun identify(userKey: String)

    fun stringVariation(key: String, defaultValue: String): String

    fun track(key: String)

    /**
     * Force-flushes buffered events. Useful while testing; a real app leaves
     * the default batching alone.
     */
    fun flush()

    companion object {
        /**
         * Starts the flag client. Returns immediately with a [Future] that
         * resolves once flag values are available.
         */
        fun init(application: Application, mobileKey: String, userKey: String): Future<FeatureFlags> {
            if (mobileKey.isBlank() || mobileKey == "mob-YOUR-MOBILE-KEY") {
                android.util.Log.w(
                    "FeatureFlags",
                    "No mobile key configured; serving caller defaults.",
                )
            }

            return ImmediateFuture(StaticFeatureFlags())
        }
    }
}

/** Hardcoded defaults: every evaluation returns the caller's fallback. */
class StaticFeatureFlags : FeatureFlags {

    override fun identify(userKey: String) = Unit

    override fun stringVariation(key: String, defaultValue: String): String = defaultValue

    override fun track(key: String) = Unit

    override fun flush() = Unit
}

/**
 * A [Future] that is already complete. Exists so [FeatureFlags.init] can hand
 * back the same shape a real async client would without pulling in
 * `CompletableFuture`, which needs API 24 and this app runs on 21.
 */
private class ImmediateFuture<T>(private val value: T) : Future<T> {
    override fun cancel(mayInterruptIfRunning: Boolean): Boolean = false
    override fun isCancelled(): Boolean = false
    override fun isDone(): Boolean = true
    override fun get(): T = value
    override fun get(timeout: Long, unit: TimeUnit): T = value
}
