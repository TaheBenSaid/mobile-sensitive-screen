package com.tahebensaid.sensitivescreen

import android.app.Activity
import android.os.Build
import android.view.WindowManager
import androidx.annotation.RequiresApi
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricManager.Authenticators.BIOMETRIC_WEAK
import androidx.biometric.BiometricManager.Authenticators.DEVICE_CREDENTIAL
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity

/** Screenshots and recordings come out black, and recents shows a blank card. */
object ScreenShield {
    fun set(activity: Activity, enabled: Boolean) {
        val flag = WindowManager.LayoutParams.FLAG_SECURE
        if (enabled) activity.window.addFlags(flag) else activity.window.clearFlags(flag)
    }
}

/**
 * Hides the preview in recents but still lets the user take screenshots.
 * Only needed when the shield is off. Returns false below Android 13.
 */
object RecentsCover {
    fun set(activity: Activity, enabled: Boolean): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return false
        activity.setRecentsScreenshotEnabled(!enabled)
        return true
    }
}

enum class BiometricResult { GRANTED, DENIED, UNAVAILABLE }

object BiometricGate {
    // STRONG or DEVICE_CREDENTIAL isn't allowed on Android 9 and 10; WEAK or DEVICE_CREDENTIAL is.
    private const val AUTHENTICATORS = BIOMETRIC_WEAK or DEVICE_CREDENTIAL

    fun authenticate(activity: FragmentActivity, title: String, onResult: (BiometricResult) -> Unit) {
        if (BiometricManager.from(activity).canAuthenticate(AUTHENTICATORS) != BiometricManager.BIOMETRIC_SUCCESS) {
            onResult(BiometricResult.UNAVAILABLE)
            return
        }
        // onAuthenticationFailed is one bad finger, the prompt stays open, so it isn't handled.
        val callback = object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) =
                onResult(BiometricResult.GRANTED)

            override fun onAuthenticationError(code: Int, message: CharSequence) =
                onResult(BiometricResult.DENIED)
        }
        val info = BiometricPrompt.PromptInfo.Builder()
            .setTitle(title)
            .setAllowedAuthenticators(AUTHENTICATORS)
            .build()
        BiometricPrompt(activity, ContextCompat.getMainExecutor(activity), callback).authenticate(info)
    }
}

/**
 * Tells you when the user took a screenshot (Android 14+). Needs
 * `<uses-permission android:name="android.permission.DETECT_SCREEN_CAPTURE" />`.
 * Register in onStart and unregister in onStop.
 */
class ScreenshotWatcher(private val activity: Activity, onScreenshot: () -> Unit) {
    private val callback: Any? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) captureCallback(onScreenshot) else null

    fun start() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            activity.registerScreenCaptureCallback(activity.mainExecutor, callback as Activity.ScreenCaptureCallback)
        }
    }

    fun stop() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            activity.unregisterScreenCaptureCallback(callback as Activity.ScreenCaptureCallback)
        }
    }

    @RequiresApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
    private fun captureCallback(onScreenshot: () -> Unit) = Activity.ScreenCaptureCallback { onScreenshot() }
}
