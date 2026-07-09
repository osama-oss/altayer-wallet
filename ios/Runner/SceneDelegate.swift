import Flutter
import UIKit

/// Adds a full-screen privacy overlay whenever the app leaves the foreground so
/// sensitive banking content never appears in the iOS app-switcher snapshot.
///
/// NOTE: iOS provides no API to *block* screenshots/recording (only to detect
/// them after the fact). This overlay — together with Android's FLAG_SECURE —
/// is the app-switcher / defense-in-depth control. It composes with the app's
/// existing idle app-lock (returning to foreground still requires biometric
/// unlock after the timeout).
class SceneDelegate: FlutterSceneDelegate {
  private static let overlayTag = 0x5EC0 // marker for the privacy overlay view

  // Add the overlay BEFORE iOS snapshots the scene for the app switcher.
  override func sceneWillResignActive(_ scene: UIScene) {
    super.sceneWillResignActive(scene) // REQUIRED: forwards lifecycle to Flutter plugins
    guard let window = self.window ?? (scene as? UIWindowScene)?.windows.first,
          window.viewWithTag(SceneDelegate.overlayTag) == nil else { return }

    // Opaque brand backdrop (banking norm — never just a blur) + blur on top.
    // Added synchronously, no animation, so nothing leaks into the snapshot.
    let overlay = UIView(frame: window.bounds)
    overlay.tag = SceneDelegate.overlayTag
    overlay.backgroundColor = UIColor(
      red: 0x16 / 255.0, green: 0x10 / 255.0, blue: 0xB0 / 255.0, alpha: 1.0)
    overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]

    let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterialDark))
    blur.frame = overlay.bounds
    blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    overlay.addSubview(blur)

    if let logo = UIImage(named: "LaunchImage") {
      let imageView = UIImageView(image: logo)
      imageView.contentMode = .scaleAspectFit
      imageView.translatesAutoresizingMaskIntoConstraints = false
      overlay.addSubview(imageView)
      NSLayoutConstraint.activate([
        imageView.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
        imageView.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
        imageView.widthAnchor.constraint(equalToConstant: 140),
      ])
    }

    window.addSubview(overlay)
  }

  // Remove the overlay only once the user is truly back in the foreground.
  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene) // REQUIRED
    let window = self.window ?? (scene as? UIWindowScene)?.windows.first
    window?.viewWithTag(SceneDelegate.overlayTag)?.removeFromSuperview()
  }
}
