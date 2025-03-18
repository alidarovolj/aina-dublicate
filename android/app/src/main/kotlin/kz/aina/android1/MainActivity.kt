package kz.aina.android1

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.util.Log

class MainActivity: FlutterActivity() {
    private val CHANNEL = "app.channel/back_button"
    private val DEEP_LINK_CHANNEL = "kz.aina/deep_links"
    private var canPopRoute = true
    private lateinit var deepLinkChannel: MethodChannel

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Back button channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setCanPop" -> {
                    canPopRoute = call.arguments as Boolean
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Deep link channel
        deepLinkChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEEP_LINK_CHANNEL)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        // Get the action and data from the intent
        val action = intent.action
        val data = intent.data

        Log.d("DeepLink", "Handling intent: action=$action, data=$data")

        if (Intent.ACTION_VIEW == action && data != null) {
            val link = data.toString()
            Log.d("DeepLink", "Received deep link: $link")
            
            // Make sure the Flutter engine and channel are initialized
            if (flutterEngine != null) {
                deepLinkChannel.invokeMethod("handleDeepLink", link)
            } else {
                Log.e("DeepLink", "Flutter engine is null")
            }
        }
    }

    override fun onBackPressed() {
        if (canPopRoute) {
            super.onBackPressed()
        } else {
            finishAffinity()
        }
    }
} 