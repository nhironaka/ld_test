package com.example.darkstore

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf

/**
 * Central seam for every runtime feature decision in the app.
 *
 * Today each method returns a hardcoded constant. The intent is for them to
 * consult a remote flag evaluation service so we can roll changes out
 * gradually instead of shipping a release per toggle.
 *
 * Two client-side details the implementation has to honour:
 *  - [start] runs on a background thread during `Application.onCreate`, and
 *    must not block the main thread waiting for a first payload.
 *  - [identify] is called on login/logout; flag values are expected to change
 *    afterwards, which is why the read APIs are [Flow]s and not plain getters.
 */
interface FeatureFlags {
    suspend fun start(actor: Actor)

    suspend fun identify(actor: Actor)

    /** Boolean rollout: gates the rebuilt checkout funnel. */
    fun checkoutRedesign(): Flow<Boolean>

    /** String variation: marketing copy for the storefront banner. */
    fun bannerCopy(): Flow<String>

    /** Numeric variation: per-plan cart ceiling. */
    fun maxCartItems(): Flow<Int>
}

/** Hardcoded defaults. Emits once and never changes. */
class StaticFeatureFlags : FeatureFlags {
    override suspend fun start(actor: Actor) = Unit

    override suspend fun identify(actor: Actor) = Unit

    override fun checkoutRedesign(): Flow<Boolean> = flowOf(false)

    override fun bannerCopy(): Flow<String> = flowOf("Free shipping on orders over \$50")

    override fun maxCartItems(): Flow<Int> = flowOf(25)
}
