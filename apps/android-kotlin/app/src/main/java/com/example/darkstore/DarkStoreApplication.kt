package com.example.darkstore

import android.app.Application
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

class DarkStoreApplication : Application() {

    /** Long-lived scope for process-wide setup that outlives any Activity. */
    private val appScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    lateinit var featureFlags: FeatureFlags
        private set

    override fun onCreate() {
        super.onCreate()

        featureFlags = StaticFeatureFlags()

        appScope.launch {
            featureFlags.start(Actor.ANONYMOUS)
        }
    }
}
