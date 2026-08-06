#if os(iOS) || os(tvOS)
import UIKit

/// The window a view is hosted in while it renders, which decides how its pixels are taken.
enum ViewHost: Sendable {
  /// A window this library makes, which never reaches the screen.
  ///
  /// The view's layer tree is drawn directly, so the result depends on nothing outside the
  /// process. Nothing is composited: a visual effect contributes its tint but not its blur.
  case offscreenWindow

  /// The host application's key window.
  ///
  /// The view is drawn as it is composited onscreen, which is the only way to capture
  /// `UIAppearance` and `UIVisualEffect`s. A test bundle with no host application has no key
  /// window to draw into.
  case keyWindow
}

extension ViewHost {
  /// Answers the window to host a view controller in, along with how to leave that window as it
  /// was found.
  ///
  /// - Throws: ``ViewHostingError/keyWindowUnavailable`` when ``keyWindow`` is asked of a process
  ///   that has no key window.
  @MainActor
  func window(
    for viewController: UIViewController,
    profile: DeviceProfile,
    size: CGSize,
    traits: @escaping TraitMutations
  ) throws -> (window: UIWindow, restore: () -> Void) {
    switch self {
    case .offscreenWindow:
      let window = OffscreenWindow(
        profile: .init(safeArea: profile.safeArea, size: profile.size ?? size, traits: traits),
        viewController: viewController
      )
      return (window, {})

    case .keyWindow:
      guard let keyWindow = getKeyWindow() else {
        throw ViewHostingError.keyWindowUnavailable
      }
      // The key window belongs to the host application and outlives the snapshot, so its geometry
      // is borrowed for the render and handed back afterwards.
      let originalFrame = keyWindow.frame
      keyWindow.frame.size = size
      return (keyWindow, { keyWindow.frame = originalFrame })
    }
  }

  /// Draws a hosted view into an image context.
  ///
  /// The mechanism has to match the window: `drawHierarchy` reads back what the render server
  /// composited, and a window that never reaches the screen has nothing there to read.
  @MainActor
  func draw(_ view: UIView, into context: UIGraphicsImageRendererContext) {
    switch self {
    case .offscreenWindow:
      view.layer.render(in: context.cgContext)
    case .keyWindow:
      view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
    }
  }
}

@MainActor
private func getKeyWindow() -> UIWindow? {
  UIApplication.sharedIfAvailable?.connectedScenes
    .compactMap { ($0 as? UIWindowScene)?.keyWindow }
    .first
}
#endif
