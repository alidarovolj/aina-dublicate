package kz.aina.android1

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "app.channel/back_button"
    private var canPopRoute = true

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setCanPop" -> {
                    canPopRoute = call.arguments as Boolean
                    result.success(null)
                }
                else -> result.notImplemented()
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