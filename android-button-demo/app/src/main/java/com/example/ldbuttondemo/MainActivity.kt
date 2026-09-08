package com.example.ldbuttondemo

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import com.launchdarkly.sdk.android.LDClient
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.util.concurrent.TimeUnit

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    ButtonCopyScreen()
                }
            }
        }
    }
}

@Composable
fun ButtonCopyScreen() {
    var client by remember { mutableStateOf<LDClient?>(null) }
    var buttonLabel by remember { mutableStateOf("Loading…") }
    var tapCount by remember { mutableIntStateOf(0) }

    // Await SDK initialization off the main thread, then read the flag once ready.
    LaunchedEffect(Unit) {
        withContext(Dispatchers.IO) {
            val ldClient = LDApplication.clientFuture.get(5, TimeUnit.SECONDS)
            withContext(Dispatchers.Main) {
                client = ldClient
                buttonLabel = ldClient.stringVariation(Config.FLAG_KEY, "Get started")
            }
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Button(
            onClick = {
                client?.track(Config.METRIC_KEY)
                tapCount++
            },
            enabled = client != null,
            modifier = Modifier
                .fillMaxWidth()
                .height(52.dp),
        ) {
            Text(buttonLabel)
        }

        Spacer(Modifier.height(16.dp))

        // Snippet-style View button — uses configureExperimentButton() from ExperimentButton.kt.
        // Rendered only after the SDK is ready so LDClient.get() is non-null inside the snippet.
        if (client != null) {
            AndroidView(
                modifier = Modifier.fillMaxWidth(),
                factory = { ctx ->
                    android.widget.Button(ctx).also { btn ->
                        configureExperimentButton(btn) { tapCount++ }
                    }
                },
            )
            Spacer(Modifier.height(16.dp))
        }

        Text(
            text = "Experiment taps: $tapCount",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )

        Spacer(Modifier.height(8.dp))

        Text(
            text = "Flag: ${Config.FLAG_KEY}\nMetric: ${Config.METRIC_KEY}",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
        )
    }
}
