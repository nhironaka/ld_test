package com.example.ldbuttondemo

import android.app.Application
import java.util.concurrent.Future

class LDApplication : Application() {

    companion object {
        // Resolves once flag values are available; await it off the main thread.
        lateinit var flagsFuture: Future<FeatureFlags>
    }

    override fun onCreate() {
        super.onCreate()

        flagsFuture = FeatureFlags.init(
            application = this,
            mobileKey = Config.MOBILE_KEY,
            userKey = Config.USER_EMAIL,
        )
    }
}
