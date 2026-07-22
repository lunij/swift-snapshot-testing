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

  func addImagesForRenderedViews(_ view: XView) -> [Async<XView>] {
    return view.snapshot
      .map { async in
        [
          Async { callback in
            async.run { image in
              let imageView = XImageView()
              imageView.image = image
              imageView.frame = view.frame
              #if os(macOS)
                view.superview?.addSubview(imageView, positioned: .above, relativeTo: view)
              #elseif os(iOS) || os(tvOS)
                view.superview?.insertSubview(imageView, aboveSubview: view)
              #endif
              callback(imageView)
            }
          }
        ]
      }
      ?? view.subviews.flatMap(addImagesForRenderedViews)
  }

  extension XView {
    var snapshot: Async<XImage>? {
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
        return Async(value: inWindow { scnView.snapshot() })
      } else if let skView = self as? SKView {
        if #available(macOS 10.11, *) {
          let cgImage = inWindow { skView.texture(from: skView.scene!)!.cgImage() }
          #if os(macOS)
            let image = XImage(cgImage: cgImage, size: skView.bounds.size)
          #elseif os(iOS) || os(tvOS)
            let image = XImage(cgImage: cgImage)
          #endif
          return Async(value: image)
        } else {
          fatalError("Taking SKView snapshots requires macOS 10.11 or greater")
        }
      }
      #if os(iOS) || os(macOS)
        if let wkWebView = self as? WKWebView {
          return Async<XImage> { callback in
            let work = {
              #if os(macOS)
                // The window must stay alive until `takeSnapshot` completes;
                // tearing it down earlier yields blank or failed captures.
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
                    _ = window
                    superview?.addSubview(wkWebView)
                  #endif
                  guard let image else {
                    debugPrint("No image taken. Error: \(error.description)")
                    callback(XImage())
                    return
                  }
                  callback(image)
                }
              }
            }

            if wkWebView.isLoading {
              var subscription: NSKeyValueObservation?
              var didWork = false
              let workOnce = {
                guard !didWork else { return }
                didWork = true
                subscription?.invalidate()
                subscription = nil
                // Loading can finish inside the same runloop callout that
                // invokes navigation delegates; hop the main queue so any
                // JavaScript they enqueue is submitted before the snapshot's.
                DispatchQueue.main.async(execute: work)
              }
              subscription = wkWebView.observe(\.isLoading, options: [.new]) { _, change in
                if change.newValue == false {
                  workOnce()
                }
              }
              // The load may have finished between the `isLoading` check
              // above and installing the observer.
              if !wkWebView.isLoading {
                workOnce()
              }
            } else {
              work()
            }
          }
        }
      #endif
      return nil
    }
    #if os(iOS) || os(tvOS)
      func asImage() -> XImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
          layer.render(in: rendererContext.cgContext)
        }
      }
    #endif

    #if os(macOS)
      func convertToImage(scale: CGFloat) -> XImage {
        let originalSize = bounds.size
        let scaledSize = NSSize(width: originalSize.width * scale, height: originalSize.height * scale)
        let image = NSImage(size: scaledSize)

        guard let bitmapRep = NSBitmapImageRep(
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
        ) else {
          return image
        }

        let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmapRep)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = graphicsContext
        
        graphicsContext?.cgContext.scaleBy(x: scale, y: scale)
        cacheDisplay(in: bounds, to: bitmapRep)

        NSGraphicsContext.restoreGraphicsState()
        image.addRepresentation(bitmapRep)
        return image
      }
    #elseif os(iOS) || os(tvOS)
    func convertToImage(scale: CGFloat, traits: @escaping TraitMutations, drawHierarchyInKeyWindow: Bool) -> XImage {
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
      static var sharedIfAvailable: UIApplication? {
        let sharedSelector = NSSelectorFromString("sharedApplication")
        guard UIApplication.responds(to: sharedSelector) else {
          return nil
        }

        let shared = UIApplication.perform(sharedSelector)
        return shared?.takeUnretainedValue() as! UIApplication?
      }
    }

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

    func snapshotView(
      config: ViewImageConfig,
      drawHierarchyInKeyWindow: Bool,
      traits: @escaping TraitMutations,
      view: UIView,
      viewController: UIViewController
    )
      -> Async<UIImage>
    {
      let initialFrame = view.frame
      let dispose = prepareView(
        config: config,
        drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
        traits: traits,
        view: view,
        viewController: viewController
      )
      let teardown = SnapshotTeardown(dispose)
      PendingSnapshotTeardowns.register(teardown)
      return Async { callback in
        addImagesForRenderedViews(view).sequence().run { views in
          callback(view.convertToImage(scale: config.scale, traits: traits, drawHierarchyInKeyWindow: drawHierarchyInKeyWindow))
          views.forEach { $0.removeFromSuperview() }
          view.frame = initialFrame
        }
      }.map {
        PendingSnapshotTeardowns.unregister(teardown)
        teardown.run()
        return $0
      }
    }

    func renderer(bounds: CGRect, scale: CGFloat, traits: @escaping TraitMutations) -> UIGraphicsImageRenderer {
      let format = UIGraphicsImageRendererFormat(for: UITraitCollection(mutations: traits))
      format.scale = scale
      return UIGraphicsImageRenderer(bounds: bounds, format: format)
    }

    private func add(
      traits: @escaping TraitMutations, viewController: UIViewController, to window: UIWindow
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
              equalTo: rootViewController.view.bottomAnchor),
            viewController.view.leadingAnchor.constraint(
              equalTo: rootViewController.view.leadingAnchor),
            viewController.view.trailingAnchor.constraint(
              equalTo: rootViewController.view.trailingAnchor),
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

      @available(iOS 11.0, *)
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

extension Array {
  func sequence<A>() -> Async<[A]> where Element == Async<A> {
    guard !self.isEmpty else { return Async(value: []) }
    return Async<[A]> { callback in
      var result = [A?](repeating: nil, count: self.count)
      result.reserveCapacity(self.count)
      var count = 0
      zip(self.indices, self).forEach { idx, async in
        async.run {
          result[idx] = $0
          count += 1
          if count == self.count {
            callback(result as! [A])
          }
        }
      }
    }
  }
}

extension Optional {
    var description: String {
        if let value = self {
            return String(describing: value)
        } else {
            return "nil"
        }
    }
}
