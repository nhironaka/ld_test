package com.example.ldbuttondemo

import android.app.Application
import com.launchdarkly.sdk.ContextKind
import com.launchdarkly.sdk.LDContext
import com.launchdarkly.sdk.android.LDClient
import com.launchdarkly.sdk.android.LDConfig
import java.util.concurrent.Future

class LDApplication : Application() {

    companion object {
        // Nullable until init() completes; read via LDClient.get() after the Future resolves.
        lateinit var clientFuture: Future<LDClient>
    }

    override fun onCreate() {
        super.onCreate()

        val ldConfig = LDConfig.Builder(LDConfig.Builder.AutoEnvAttributes.Enabled)
            .mobileKey(Config.MOBILE_KEY)
            .build()

        val context = LDContext.builder(ContextKind.of("user"), Config.USER_EMAIL)
            .set("email", Config.USER_EMAIL)
            .build()

        clientFuture = LDClient.init(this, ldConfig, context)
    }
}
