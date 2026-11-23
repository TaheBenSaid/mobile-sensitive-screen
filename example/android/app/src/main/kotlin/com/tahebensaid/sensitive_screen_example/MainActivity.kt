package com.tahebensaid.sensitive_screen_example

import com.tahebensaid.sensitivescreen.BiometricGate
import com.tahebensaid.sensitivescreen.BiometricResult
import com.tahebensaid.sensitivescreen.RecentsCover
import com.tahebensaid.sensitivescreen.ScreenShield
import com.tahebensaid.sensitivescreen.ScreenshotWatcher
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// BiometricPrompt needs a FragmentActivity, so this extends FlutterFragmentActivity.
class MainActivity : FlutterFragmentActivity() {
    private var watcher: ScreenshotWatcher? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sensitive_screen")
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "authenticate" -> BiometricGate.authenticate(this, call.arguments as? String ?: "") {
                    when (it) {
                        BiometricResult.GRANTED -> result.success(true)
                        BiometricResult.DENIED -> result.success(false)
                        BiometricResult.UNAVAILABLE -> result.error("unavailable", null, null)
                    }
                }
                "setShield" -> {
                    ScreenShield.set(this, call.arguments == true)
                    result.success(true)
                }
                "setCover" -> result.success(RecentsCover.set(this, call.arguments == true))
                else -> result.notImplemented()
            }
        }
        watcher = ScreenshotWatcher(this) { channel.invokeMethod("screenshot", null) }
    }

    override fun onStart() {
        super.onStart()
        watcher?.start()
    }

    override fun onStop() {
        watcher?.stop()
        super.onStop()
    }
}
