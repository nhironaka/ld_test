package com.example.darkstore

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn

data class StorefrontUiState(
    val banner: String = "",
    val checkout: String = "legacy",
    val cartLimit: Int = 0,
)

class StorefrontViewModel(private val featureFlags: FeatureFlags) : ViewModel() {

    val uiState: StateFlow<StorefrontUiState> = combine(
        featureFlags.bannerCopy(),
        featureFlags.checkoutRedesign(),
        featureFlags.maxCartItems(),
    ) { banner, redesign, cartLimit ->
        StorefrontUiState(
            banner = banner,
            checkout = if (redesign) "redesign" else "legacy",
            cartLimit = cartLimit,
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = StorefrontUiState(),
    )

    fun onSignIn(actor: Actor) {
        viewModelScope.launchIdentify(featureFlags, actor)
    }

    class Factory(private val featureFlags: FeatureFlags) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T =
            StorefrontViewModel(featureFlags) as T
    }
}
