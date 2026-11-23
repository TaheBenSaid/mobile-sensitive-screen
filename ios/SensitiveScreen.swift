import LocalAuthentication
import UIKit

/// Keeps a window out of screenshots, screen recordings and AirPlay mirroring.
///
/// iOS has no public flag for this. UIKit already leaves the canvas of a secure
/// text field out of every capture, so the window's layer is moved into that
/// canvas and `isSecureTextEntry` becomes the on/off switch. It leans on UIKit
/// internals: test it on every new major iOS release before you ship.
public final class ScreenShield {
  private let field = UITextField()
  private var installed = false

  public init() {}

  /// Call it once the window is on screen. Returns false when it couldn't attach.
  @discardableResult
  public func set(_ enabled: Bool, in window: UIWindow? = nil) -> Bool {
    guard installed || install(in: window ?? Self.keyWindow) else { return false }
    field.isSecureTextEntry = enabled
    return true
  }

  private func install(in window: UIWindow?) -> Bool {
    guard let window, let host = window.layer.superlayer else { return false }

    field.isUserInteractionEnabled = false
    window.addSubview(field)
    let backdrop = CALayer()
    backdrop.backgroundColor = UIColor.black.cgColor
    backdrop.frame = window.bounds
    host.addSublayer(backdrop)
    host.addSublayer(field.layer)
    guard let canvas = field.layer.sublayers?.last else { return false }
    canvas.addSublayer(window.layer)
    installed = true
    return true
  }

  static var keyWindow: UIWindow? {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first { $0.isKeyWindow }
  }
}

/// Blurs the window so the app switcher never shows what was on screen.
/// Call `cover(_:)` from `sceneWillResignActive` and `uncover()` from `sceneDidBecomeActive`.
public final class PrivacyCover {
  public static let shared = PrivacyCover()

  public var enabled = true
  /// Face ID and the passcode sheet also resign the scene. Without this the user
  /// would authenticate in front of a blurred screen.
  public var paused = false
  private var view: UIVisualEffectView?

  public func cover(_ window: UIWindow?) {
    guard enabled, !paused, view == nil, let window else { return }
    let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterialDark))
    blur.frame = window.bounds
    blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    window.addSubview(blur)
    view = blur
  }

  public func uncover() {
    view?.removeFromSuperview()
    view = nil
  }
}

public enum BiometricResult {
  case granted, denied, unavailable
}

public enum BiometricGate {
  /// Face ID or Touch ID, falling back to the device passcode.
  /// Needs `NSFaceIDUsageDescription` in Info.plist.
  public static func authenticate(reason: String, completion: @escaping (BiometricResult) -> Void) {
    let context = LAContext()
    var error: NSError?
    guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
      completion(.unavailable)
      return
    }
    PrivacyCover.shared.paused = true
    context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { ok, _ in
      DispatchQueue.main.async {
        PrivacyCover.shared.paused = false
        completion(ok ? .granted : .denied)
      }
    }
  }
}

/// iOS can't block a screenshot without the shield, but it tells you one was taken.
public final class ScreenshotWatcher {
  private var token: NSObjectProtocol?

  public init(_ onScreenshot: @escaping () -> Void) {
    token = NotificationCenter.default.addObserver(
      forName: UIApplication.userDidTakeScreenshotNotification,
      object: nil,
      queue: .main
    ) { _ in onScreenshot() }
  }

  deinit {
    if let token { NotificationCenter.default.removeObserver(token) }
  }
}
