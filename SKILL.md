---
name: sensitive-screen
description: Use when building or reviewing any mobile screen that shows card numbers, PINs, CVVs, IBANs, balances, one-time codes, recovery phrases or ID documents. Applies the unlock, auto-hide, screenshot shield and app switcher blur from mobile-sensitive-screen.
---

# Sensitive screen

When a screen shows sensitive data, a plain text widget is not enough. Apply all
of these unless the user says otherwise.

1. Mask by default. Last 4 digits at most.
2. Reveal only after Face ID, fingerprint or device passcode.
   - iOS: `LAContext` with `.deviceOwnerAuthentication`, plus `NSFaceIDUsageDescription`.
   - Android: `BiometricPrompt` with `BIOMETRIC_WEAK or DEVICE_CREDENTIAL` (STRONG plus
     credential fails on Android 9 and 10). The activity must be a `FragmentActivity`.
3. Hide again after 10 seconds, on tap, when the app goes to the background, and when the
   screen is left. Do not hide on "inactive": the Face ID sheet triggers it.
4. PINs and CVVs show only while a finger is down (pointer down, up and cancel).
5. Block captures on that screen.
   - Android: `FLAG_SECURE`.
   - iOS: host the window layer in a secure `UITextField` canvas (see `ios/SensitiveScreen.swift`).
     Say that it relies on UIKit internals and must be checked on a real device.
6. Blur in the app switcher. iOS: blur view on `sceneWillResignActive`, paused during Face ID.
   Android: `FLAG_SECURE` already does it, or `setRecentsScreenshotEnabled(false)` on 13+.
7. Listen for screenshots: `userDidTakeScreenshotNotification` on iOS,
   `registerScreenCaptureCallback` on Android 14+ with `DETECT_SCREEN_CAPTURE`.
8. Never log, cache, notify or send the value to analytics. Fetch it after the unlock.

Reference code: `ios/SensitiveScreen.swift`, `android/SensitiveScreen.kt`,
`example/lib/reveal.dart`. Review list: `CHECKLIST.md`.
