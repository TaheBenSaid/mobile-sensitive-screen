import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let shield = ScreenShield()
  private var watcher: ScreenshotWatcher?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "sensitive_screen",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "authenticate":
        BiometricGate.authenticate(reason: call.arguments as? String ?? "") { res in
          switch res {
          case .granted: result(true)
          case .denied: result(false)
          case .unavailable: result(FlutterError(code: "unavailable", message: nil, details: nil))
          }
        }
      case "setShield":
        result(self?.shield.set(call.arguments as? Bool ?? false) ?? false)
      case "setCover":
        PrivacyCover.shared.enabled = call.arguments as? Bool ?? true
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    watcher = ScreenshotWatcher { [weak channel] in
      channel?.invokeMethod("screenshot", arguments: nil)
    }
  }
}
