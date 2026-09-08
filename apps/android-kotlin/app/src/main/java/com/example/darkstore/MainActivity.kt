package com.example.darkstore

import android.os.Bundle
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import com.example.darkstore.databinding.ActivityMainBinding
import kotlinx.coroutines.launch

class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding

    private val viewModel: StorefrontViewModel by viewModels {
        StorefrontViewModel.Factory(
            (application as DarkStoreApplication).featureFlags,
        )
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        binding.signInButton.setOnClickListener {
            viewModel.onSignIn(
                Actor(key = "user-1", email = "shopper@example.com", plan = "pro"),
            )
        }

        lifecycleScope.launch {
            repeatOnLifecycle(Lifecycle.State.STARTED) {
                viewModel.uiState.collect { state ->
                    binding.bannerText.text = state.banner
                    binding.checkoutText.text =
                        getString(R.string.checkout_variant, state.checkout)
                    binding.cartLimitText.text =
                        getString(R.string.cart_limit, state.cartLimit)
                }
            }
        }
    }
}
