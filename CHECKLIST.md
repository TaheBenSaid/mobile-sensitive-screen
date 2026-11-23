# Sensitive screen checklist

Run this on any screen that shows a card number, CVV, PIN, IBAN, balance,
one-time code, recovery phrase, ID document or health data.

## Before it shows

- [ ] The value is masked by default. Show the last 4 digits at most.
- [ ] Showing it needs Face ID, fingerprint or the device passcode, every time.
- [ ] The full value is fetched after the unlock, not preloaded with the screen.
- [ ] "No biometrics set up" gets its own message, not a silent failure.

## While it shows

- [ ] It hides again on its own (10 seconds is a good default) and shows a countdown.
- [ ] Tapping it again hides it right away.
- [ ] PINs and CVVs show only while the finger is down.
- [ ] Copy to clipboard is opt-in. If you allow it, clear the clipboard after a minute,
      and on iOS mark it local only (`UIPasteboard` `localOnly`) so it doesn't sync.

## Leaving the screen

- [ ] Going to the background hides it, but the Face ID sheet doesn't.
- [ ] The app switcher shows a blur or a blank card, never the value.
- [ ] Navigating away hides it. Coming back starts masked.

## Captures

- [ ] Screenshots and screen recordings come out black on this screen
      (`FLAG_SECURE` on Android, the secure layer on iOS).
- [ ] If you allow screenshots elsewhere, turn the shield on for this screen only.
- [ ] You know when a screenshot was taken, and you react (hide, warn, or log it).
- [ ] Tested on a real device. Simulator captures ignore the iOS shield.

## Never

- [ ] The value never goes into logs, analytics, crash reports or error messages.
- [ ] It never goes into a push notification or a home screen widget.
- [ ] It isn't cached on disk to make the screen open faster.
