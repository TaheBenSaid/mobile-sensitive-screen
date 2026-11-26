# mobile-sensitive-screen

_By [Tahe Ben Said](https://tahebensaid.dev), senior mobile engineer. More apps and tools at [tahebensaid.dev](https://tahebensaid.dev)._

Your app shows a card number, an IBAN, a balance or a one-time code. The user's
phone then puts that screen in three places they never asked for: the app
switcher, a screenshot that syncs to their cloud photos, and a screen recording
that some "support" app is running in the background.

Ask an AI agent to "show the card number" and you get a `Text` widget. None of
the protections below come with it. They're short, mostly native, and easy to
miss, so here they are, pulled out of a card wallet app I built.

| | iOS | Android |
| --- | --- | --- |
| Unlock with Face ID, fingerprint or passcode | `LAContext` | `BiometricPrompt` |
| Screenshots and recordings come out black | secure text field layer trick | `FLAG_SECURE` |
| Blur in the app switcher | blur view on `sceneWillResignActive` | `FLAG_SECURE`, or `setRecentsScreenshotEnabled` (13+) |
| Know when a screenshot was taken | `userDidTakeScreenshotNotification` | `ScreenCaptureCallback` (14+) |
| Hide again after 10 seconds, on background, on leave | `reveal.dart` | `reveal.dart` |
| Show a PIN only while a finger is down | `reveal.dart` | `reveal.dart` |

## What's in here

```
ios/SensitiveScreen.swift      UIKit only, drop into any iOS app
android/SensitiveScreen.kt     Android only, drop into any Android app
example/                       Flutter app wiring both through one method channel
  lib/sensitive_screen.dart    the Dart side of the channel
  lib/reveal.dart              SecureReveal and HoldToReveal widgets
CHECKLIST.md                   review list for any screen with sensitive data
SKILL.md                       the same rules as a skill for your coding agent
```

The native files don't depend on Flutter. Native iOS and Android apps use them
as they are. React Native or KMP apps wrap them in a native module, the same way
`example/` wraps them in a method channel.

## The iOS screenshot trick

Android has `FLAG_SECURE`. iOS has nothing public. But UIKit already keeps the
contents of a password field out of screenshots, recordings and AirPlay. So
`ScreenShield` moves the whole window's layer inside a secure text field's
canvas, and `isSecureTextEntry` becomes an on/off switch for the screen.

It relies on how UIKit draws secure fields, not on a documented API, so check
it on a real device with every new major iOS version. The simulator's own capture tools read the frame
buffer directly and ignore it, so test with a real screenshot on a real iPhone.

## Two details people get wrong

**The Face ID sheet makes your app inactive.** If you blur on `inactive`, or
hide the secret on `AppLifecycleState.inactive`, the user unlocks and then
looks at a blurred or hidden screen. `PrivacyCover.paused` and `onHide`
(instead of `onInactive`) in `SecureReveal` handle that.

**Android 9 and 10 reject `BIOMETRIC_STRONG or DEVICE_CREDENTIAL`.** The gate
uses `BIOMETRIC_WEAK or DEVICE_CREDENTIAL`, which works everywhere from API 23
and still falls back to the PIN when there's no fingerprint.

## Run the example

```bash
cd example
flutter run
```

Android needs `FlutterFragmentActivity` (BiometricPrompt shows a fragment) and
`androidx.biometric:biometric`. iOS needs `NSFaceIDUsageDescription` in
Info.plist. Both are already set up in `example/`.

## What this does not do

It keeps data off the screen and out of captures. It doesn't protect data on
the device or on the wire. Don't keep the full card number in memory longer
than the screen needs it, don't log it, and fetch it only after the unlock.
On a rooted or jailbroken phone, all bets are off.

MIT licensed.
