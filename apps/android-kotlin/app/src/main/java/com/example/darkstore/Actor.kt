package com.example.darkstore

/**
 * The signed-in shopper, reduced to the attributes a targeting rule would
 * plausibly want. On a client, this changes when the user logs in or out, so
 * anything holding it needs to be re-identified rather than rebuilt.
 */
data class Actor(
    val key: String,
    val email: String? = null,
    val plan: String = "free",
    val country: String = "US",
) {
    companion object {
        val ANONYMOUS = Actor(key = "anonymous")
    }
}
