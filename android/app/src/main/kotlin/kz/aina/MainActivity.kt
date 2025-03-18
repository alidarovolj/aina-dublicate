package kz.aina

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.os.Bundle
import android.os.Build
import android.util.Log
import android.net.Uri
import android.content.pm.PackageManager

class MainActivity: FlutterActivity() {
    private val DEEP_LINK_CHANNEL = "kz.aina/deep_links"
    private var deepLinkChannel: MethodChannel? = null
    private val TAG = "MainActivity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Setup deep link channel
        deepLinkChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEEP_LINK_CHANNEL)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "onCreate called")
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        Log.d(TAG, "onNewIntent called")
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        try {
            Log.d(TAG, "handleIntent called with action: ${intent.action}")
            val data = when {
                intent.data != null -> intent.data
                intent.getStringExtra(Intent.EXTRA_TEXT) != null -> Uri.parse(intent.getStringExtra(Intent.EXTRA_TEXT))
                else -> null
            }

            if (data != null) {
                Log.d(TAG, "Deep link data found:")
                Log.d(TAG, "  - Scheme: ${data.scheme}")
                Log.d(TAG, "  - Host: ${data.host}")
                Log.d(TAG, "  - Path: ${data.path}")
                Log.d(TAG, "  - Query: ${data.query}")
                
                // Check if this is a deep link to our app
                if (data.scheme == "aina" || data.host == "app.aina-fashion.kz") {
                    // Try to resolve the intent to check if our app can handle it
                    if (packageManager.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY) != null) {
                        deepLinkChannel?.invokeMethod("handleDeepLink", data.toString())
                    } else {
                        Log.d(TAG, "App not installed, redirecting to market")
                        val marketIntent = Intent(Intent.ACTION_VIEW).apply {
                            this.data = Uri.parse("market://details?id=kz.aina.android1")
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(marketIntent)
                    }
                }
            } else {
                Log.d(TAG, "No deep link data in intent")
                Log.d(TAG, "Intent extras: ${intent.extras?.keySet()?.joinToString()}")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error handling deep link", e)
            // В случае ошибки, пробуем открыть маркет
            try {
                val marketIntent = Intent(Intent.ACTION_VIEW).apply {
                    data = Uri.parse("market://details?id=kz.aina.android1")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(marketIntent)
            } catch (e: Exception) {
                Log.e(TAG, "Error opening market", e)
            }
        }
    }

    override fun onBackPressed() {
        if (Build.VERSION.SDK_INT == Build.VERSION_CODES.Q) {
            // For Android 10, handle back press specially
            finishAffinity()
        } else {
            super.onBackPressed()
        }
    }
} 