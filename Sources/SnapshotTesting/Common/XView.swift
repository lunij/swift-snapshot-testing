#if os(iOS) || os(macOS) || os(tvOS)
#if os(macOS)
import Cocoa
#endif
import SceneKit
import SpriteKit
#if os(iOS) || os(tvOS)
import UIKit
#endif
#if os(iOS) || os(macOS)
import WebKit
#endif

@MainActor
func addImagesForRenderedViews(_ view: XView) async -> [XView] {
  if let image = await view.snapshot {
    let imageView = XImageView()
    imageView.image = image
    imageView.frame = view.frame
    #if os(macOS)
    view.superview?.addSubview(imageView, positioned: .above, relativeTo: view)
    #elseif os(iOS) || os(tvOS)
    view.superview?.insertSubview(imageView, aboveSubview: view)
    #endif
    return [imageView]
  }
  var result: [XView] = []
  for subview in view.subviews {
    result += await addImagesForRenderedViews(subview)
  }
  return result
}

extension XView {
  @MainActor var snapshot: XImage? {
    get async {
      func inWindow<T>(_ perform: () -> T) -> T {
        #if os(macOS)
        let superview = self.superview
        defer { superview?.addSubview(self) }
        let window = ScaledWindow()
        window.contentView = NSView()
        window.contentView?.addSubview(self)
        window.makeKey()
        #endif
        return perform()
      }
      if let scnView = self as? SCNView {
        return inWindow { scnView.snapshot() }
      } else if let skView = self as? SKView {
        let cgImage = inWindow { skView.texture(from: skView.scene!)!.cgImage() }
        #if os(macOS)
        return XImage(cgImage: cgImage, size: skView.bounds.size)
        #elseif os(iOS) || os(tvOS)
        return XImage(cgImage: cgImage)
        #endif
      }
      #if os(iOS) || os(macOS)
      if let wkWebView = self as? WKWebView {
        // Loading can finish inside the same runloop callout that invokes
        // navigation delegates; resuming from `Task.sleep` is a fresh
        // main-queue job, so any JavaScript they enqueue is submitted
        // before the snapshot's.
        while wkWebView.isLoading {
          try? await Task.sleep(for: .milliseconds(10))
        }
        return await withCheckedContinuation { continuation in
          #if os(macOS)
          let superview = wkWebView.superview
          let window = ScaledWindow()
          window.contentView = NSView()
          window.contentView?.addSubview(wkWebView)
          window.makeKey()
          #endif
          // This no-op script runs after any JavaScript enqueued by the
          // page or a navigation delegate (e.g. DOM manipulation in
          // `didFinish`), so the snapshot sees its effects.
          wkWebView.evaluateJavaScript("void 0") { _, _ in
            wkWebView.takeSnapshot(with: nil) { image, error in
              #if os(macOS)
              _ = window  // keep alive until takeSnapshot completes
              superview?.addSubview(wkWebView)
              #endif
              guard let image else {
                debugPrint("No image taken. Error: \(error.description)")
                continuation.resume(returning: XImage())
                return
              }
              continuation.resume(returning: image)
            }
          }
        }
      }
      #endif
      return nil
    }
  }
  #if os(iOS) || os(tvOS)
  @MainActor func asImage() -> XImage {
    let renderer = UIGraphicsImageRenderer(bounds: bounds)
    return renderer.image { rendererContext in
      layer.render(in: rendererContext.cgContext)
    }
  }
  #endif

  #if os(macOS)
  @MainActor func convertToImage(scale: CGFloat) -> XImage {
    let originalSize = bounds.size
    let scaledSize = NSSize(width: originalSize.width * scale, height: originalSize.height * scale)

    guard
      let bitmapRep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(scaledSize.width),
        pixelsHigh: Int(scaledSize.height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
      )
    else {
      return NSImage(size: originalSize)
    }

    // Setting the rep's point size to the unscaled bounds while keeping
    // its pixel dimensions at Nx causes `cacheDisplay` to render at the
    // higher backing resolution. (`cacheDisplay` ignores the current
    // NSGraphicsContext, so applying `scaleBy` to it has no effect.)
    bitmapRep.size = originalSize
    cacheDisplay(in: bounds, to: bitmapRep)

    let image = NSImage(size: originalSize)
    image.addRepresentation(bitmapRep)
    return image
  }
  #elseif os(iOS) || os(tvOS)
  @MainActor func convertToImage(scale: CGFloat, traits: @escaping TraitMutations, drawHierarchyInKeyWindow: Bool) -> XImage {
    renderer(bounds: bounds, scale: scale, traits: traits).image { ctx in
      if drawHierarchyInKeyWindow {
        drawHierarchy(in: bounds, afterScreenUpdates: true)
      } else {
        layer.render(in: ctx.cgContext)
      }
    }
  }
  #endif
}

#if os(iOS) || os(tvOS)
extension UIApplication {
  @MainActor static var sharedIfAvailable: UIApplication? {
    let sharedSelector = NSSelectorFromString("sharedApplication")
    guard UIApplication.responds(to: sharedSelector) else {
      return nil
    }

    let shared = UIApplication.perform(sharedSelector)
    return shared?.takeUnretainedValue() as! UIApplication?
  }
}

@MainActor
func prepareView(
  config: ViewImageConfig,
  drawHierarchyInKeyWindow: Bool,
  traits: @escaping TraitMutations,
  view: UIView,
  viewController: UIViewController
) -> () -> Void {
  let size = config.size ?? viewController.view.frame.size
  view.frame.size = size
  if view != viewController.view {
    viewController.view.bounds = view.bounds
    viewController.view.addSubview(view)
  }
  // Mutations run in order, so the passed-in traits override the config's,
  // mirroring the merge semantics of the old `UITraitCollection(traitsFrom:)`.
  let configTraits = config.traits
  let traits: TraitMutations = { mutableTraits in
    configTraits(&mutableTraits)
    traits(&mutableTraits)
  }
  let window: UIWindow
  if drawHierarchyInKeyWindow {
    guard let keyWindow = getKeyWindow() else {
      fatalError("'drawHierarchyInKeyWindow' requires tests to be run in a host application")
    }
    window = keyWindow
    window.frame.size = size
  } else {
    window = Window(
      config: .init(safeArea: config.safeArea, size: config.size ?? size, traits: traits),
      viewController: viewController
    )
  }
  let dispose = add(traits: traits, viewController: viewController, to: window)

  if size.width == 0 || size.height == 0 {
    // Try to call sizeToFit() if the view still has invalid size
    view.sizeToFit()
    view.setNeedsLayout()
    view.layoutIfNeeded()
  }

  return dispose
}

@MainActor
func snapshotView(
  config: ViewImageConfig,
  drawHierarchyInKeyWindow: Bool,
  traits: @escaping TraitMutations,
  view: UIView,
  viewController: UIViewController
) async -> UIImage {
  let initialFrame = view.frame
  let dispose = prepareView(
    config: config,
    drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
    traits: traits,
    view: view,
    viewController: viewController
  )
  // Metal-backed views must be captured through their own snapshot API;
  // rendering their layer yields an empty image. WKWebView is excluded:
  // its layer renders fine, and `takeSnapshot` would ignore the
  // strategy's `scale` parameter.
  if view is SCNView || view is SKView, let image = await view.snapshot {
    view.frame = initialFrame
    dispose()
    return image
  }
  let views = await addImagesForRenderedViews(view)
  let image = view.convertToImage(
    scale: config.scale,
    traits: traits,
    drawHierarchyInKeyWindow: drawHierarchyInKeyWindow
  )
  views.forEach { $0.removeFromSuperview() }
  view.frame = initialFrame
  dispose()
  return image
}

@MainActor
func renderer(bounds: CGRect, scale: CGFloat, traits: @escaping TraitMutations) -> UIGraphicsImageRenderer {
  let format = UIGraphicsImageRendererFormat(for: UITraitCollection(mutations: traits))
  format.scale = scale
  return UIGraphicsImageRenderer(bounds: bounds, format: format)
}

@MainActor
private func add(
  traits: @escaping TraitMutations,
  viewController: UIViewController,
  to window: UIWindow
) -> () -> Void {
  let rootViewController: UIViewController
  if viewController != window.rootViewController {
    rootViewController = UIViewController()
    rootViewController.view.backgroundColor = .clear
    rootViewController.view.frame = window.frame
    rootViewController.view.translatesAutoresizingMaskIntoConstraints =
      viewController.view.translatesAutoresizingMaskIntoConstraints
    rootViewController.preferredContentSize = rootViewController.view.frame.size
    viewController.view.frame = rootViewController.view.frame
    rootViewController.view.addSubview(viewController.view)
    if viewController.view.translatesAutoresizingMaskIntoConstraints {
      viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    } else {
      NSLayoutConstraint.activate([
        viewController.view.topAnchor.constraint(equalTo: rootViewController.view.topAnchor),
        viewController.view.bottomAnchor.constraint(
          equalTo: rootViewController.view.bottomAnchor
        ),
        viewController.view.leadingAnchor.constraint(
          equalTo: rootViewController.view.leadingAnchor
        ),
        viewController.view.trailingAnchor.constraint(
          equalTo: rootViewController.view.trailingAnchor
        )
      ])
    }
    rootViewController.addChild(viewController)
  } else {
    rootViewController = viewController
  }
  // Overrides propagate to descendants, so applying them on the root also
  // applies them to `viewController`. Saving the previous value lets `dispose`
  // restore the controller untouched when it is the window's own root.
  let originalTraitOverrides = rootViewController.traitOverrides
  var mutableTraits: any UIMutableTraits = rootViewController.traitOverrides
  traits(&mutableTraits)
  rootViewController.traitOverrides = mutableTraits as! UITraitOverrides
  viewController.didMove(toParent: rootViewController)

  window.rootViewController = rootViewController

  rootViewController.beginAppearanceTransition(true, animated: false)
  rootViewController.endAppearanceTransition()

  rootViewController.view.setNeedsLayout()
  rootViewController.view.layoutIfNeeded()

  viewController.view.setNeedsLayout()
  viewController.view.layoutIfNeeded()

  return {
    rootViewController.traitOverrides = originalTraitOverrides
    viewController.beginAppearanceTransition(false, animated: false)
    viewController.willMove(toParent: nil)
    viewController.view.removeFromSuperview()
    viewController.removeFromParent()
    viewController.didMove(toParent: nil)
    viewController.endAppearanceTransition()
    window.rootViewController = nil
  }
}

@MainActor
private func getKeyWindow() -> UIWindow? {
  UIApplication.sharedIfAvailable?.connectedScenes
    .compactMap { ($0 as? UIWindowScene)?.keyWindow }
    .first
}

private final class Window: UIWindow {
  var config: ViewImageConfig

  init(config: ViewImageConfig, viewController: UIViewController) {
    let size = config.size ?? viewController.view.bounds.size
    self.config = config
    super.init(frame: .init(origin: .zero, size: size))

    // NB: Safe area renders inaccurately for UI{Navigation,TabBar}Controller.
    // Fixes welcome!
    if viewController is UINavigationController {
      self.frame.size.height -= self.config.safeArea.top
      self.config.safeArea.top = 0
    } else if let viewController = viewController as? UITabBarController {
      self.frame.size.height -= self.config.safeArea.bottom
      self.config.safeArea.bottom = 0
      if viewController.selectedViewController is UINavigationController {
        self.frame.size.height -= self.config.safeArea.top
        self.config.safeArea.top = 0
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
      self.config.safeArea == .init(top: 20, left: 0, bottom: 0, right: 0)
      && self.rootViewController?.prefersStatusBarHidden ?? false
    if removeTopInset { return .zero }
    #endif
    return self.config.safeArea
  }
}
#endif

#if os(macOS)
import Cocoa

private final class ScaledWindow: NSWindow {
  override var backingScaleFactor: CGFloat {
    return 2
  }
}
#endif
#endif

extension Optional {
  var description: String {
    if let value = self {
      return String(describing: value)
    } else {
      return "nil"
    }
  }
}
