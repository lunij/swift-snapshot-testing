#if os(iOS) || os(tvOS)
import UIKit

/// A window that hosts a view for rendering without ever reaching the screen.
///
/// It reports the safe area of the device being imitated rather than the one it is running on, so a
/// snapshot is laid out for the profile it names.
final class OffscreenWindow: UIWindow {
  var profile: DeviceProfile

  init(profile: DeviceProfile, viewController: UIViewController) {
    let size = profile.size ?? viewController.view.bounds.size
    self.profile = profile
    super.init(frame: .init(origin: .zero, size: size))

    // NB: Safe area renders inaccurately for UI{Navigation,TabBar}Controller.
    // Fixes welcome!
    if viewController is UINavigationController {
      self.frame.size.height -= self.profile.safeArea.top
      self.profile.safeArea.top = 0
    } else if let viewController = viewController as? UITabBarController {
      self.frame.size.height -= self.profile.safeArea.bottom
      self.profile.safeArea.bottom = 0
      if viewController.selectedViewController is UINavigationController {
        self.frame.size.height -= self.profile.safeArea.top
        self.profile.safeArea.top = 0
      }
    }
    self.isHidden = false
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var safeAreaInsets: UIEdgeInsets {
    #if os(iOS)
    let removeTopInset =
      self.profile.safeArea == .init(top: 20, left: 0, bottom: 0, right: 0)
      && self.rootViewController?.prefersStatusBarHidden ?? false
    if removeTopInset { return .zero }
    #endif
    return self.profile.safeArea
  }
}
#endif
