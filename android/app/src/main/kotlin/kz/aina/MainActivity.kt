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
        Log.d(TAG, "Handling intent: $intent")
        
        // Get the action and data from the intent
        val action = intent.action
        val data = intent.data
        
        if (action == Intent.ACTION_VIEW && data != null) {
            Log.d(TAG, "Deep link received: ${data.toString()}")
            Log.d(TAG, "Deep link scheme: ${data.scheme}")
            Log.d(TAG, "Deep link host: ${data.host}")
            Log.d(TAG, "Deep link path: ${data.path}")
            Log.d(TAG, "Deep link query: ${data.query}")
            
            // Check if the app link is from our domain
            if (data.host == "app.aina-fashion.kz") {
                Log.d(TAG, "Sending deep link to Flutter: ${data.toString()}")
                deepLinkChannel?.invokeMethod("handleDeepLink", data.toString())
            } else {
                Log.d(TAG, "Ignoring deep link - wrong host: ${data.host}")
            }
        } else {
            Log.d(TAG, "Not a VIEW intent or no data")
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