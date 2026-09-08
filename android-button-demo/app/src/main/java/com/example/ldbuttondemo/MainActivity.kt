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
    var flags by remember { mutableStateOf<FeatureFlags?>(null) }
    var buttonLabel by remember { mutableStateOf("Loading…") }
    var tapCount by remember { mutableIntStateOf(0) }

    // Await the first payload off the main thread, then read the flag once ready.
    LaunchedEffect(Unit) {
        withContext(Dispatchers.IO) {
            val ready = LDApplication.flagsFuture.get(5, TimeUnit.SECONDS)
            withContext(Dispatchers.Main) {
                flags = ready
                buttonLabel = ready.stringVariation(Config.FLAG_KEY, "Get started")
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
                flags?.track(Config.METRIC_KEY)
                tapCount++
            },
            enabled = flags != null,
            modifier = Modifier
                .fillMaxWidth()
                .height(52.dp),
        ) {
            Text(buttonLabel)
        }

        Spacer(Modifier.height(16.dp))

        // Snippet-style View button — uses configureExperimentButton() from ExperimentButton.kt.
        // Rendered only once flag values are available.
        flags?.let { ready ->
            AndroidView(
                modifier = Modifier.fillMaxWidth(),
                factory = { ctx ->
                    android.widget.Button(ctx).also { btn ->
                        configureExperimentButton(ready, btn) { tapCount++ }
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
