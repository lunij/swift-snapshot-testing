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

  func addImagesForRenderedViews(_ view: View) -> [Async<View>] {
    return view.snapshot
      .map { async in
        [
          Async { callback in
            async.run { image in
              let imageView = ImageView()
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

  extension View {
    var snapshot: Async<Image>? {
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
            let image = Image(cgImage: cgImage, size: skView.bounds.size)
          #elseif os(iOS) || os(tvOS)
            let image = Image(cgImage: cgImage)
          #endif
          return Async(value: image)
        } else {
          fatalError("Taking SKView snapshots requires macOS 10.11 or greater")
        }
      }
      #if os(iOS) || os(macOS)
        if let wkWebView = self as? WKWebView {
          return Async<Image> { callback in
            let work = {
              if #available(iOS 11.0, macOS 10.13, *) {
                inWindow {
                  guard wkWebView.frame.width != 0, wkWebView.frame.height != 0 else {
                    callback(Image())
                    return
                  }
                  let configuration = WKSnapshotConfiguration()
                  if #available(iOS 13, macOS 10.15, *) {
                    configuration.afterScreenUpdates = false
                  }
                  wkWebView.takeSnapshot(with: configuration) { image, _ in
                    callback(image!)
                  }
                }
              } else {
                #if os(iOS)
                  fatalError("Taking WKWebView snapshots requires iOS 11.0 or greater")
                #elseif os(macOS)
                  fatalError("Taking WKWebView snapshots requires macOS 10.13 or greater")
                #endif
              }
            }

            if wkWebView.isLoading {
              var subscription: NSKeyValueObservation?
              subscription = wkWebView.observe(\.isLoading, options: [.initial, .new]) {
                (webview, change) in
                subscription?.invalidate()
                subscription = nil
                if change.newValue == false {
                  work()
                }
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
      func asImage() -> Image {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
          layer.render(in: rendererContext.cgContext)
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
      traits: UITraitCollection,
      view: UIView,
      viewController: UIViewController
    ) -> () -> Void {
      let size = config.size ?? viewController.view.frame.size
      view.frame.size = size
      if view != viewController.view {
        viewController.view.bounds = view.bounds
        viewController.view.addSubview(view)
      }
      let traits = UITraitCollection(traitsFrom: [config.traits, traits])
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
      traits: UITraitCollection,
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
      // NB: Avoid safe area influence.
      if config.safeArea == .zero { view.frame.origin = .init(x: offscreen, y: offscreen) }

      return
        (view.snapshot
        ?? Async { callback in
          addImagesForRenderedViews(view).sequence().run { views in
            callback(
              renderer(bounds: view.bounds, for: traits).image { ctx in
                if drawHierarchyInKeyWindow {
                  view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
                } else {
                  view.layer.render(in: ctx.cgContext)
                }
              }
            )
            views.forEach { $0.removeFromSuperview() }
            view.frame = initialFrame
          }
        }).map {
          dispose()
          return $0
        }
    }

    private let offscreen: CGFloat = 10_000

    func renderer(bounds: CGRect, for traits: UITraitCollection) -> UIGraphicsImageRenderer {
      let renderer: UIGraphicsImageRenderer
      if #available(iOS 11.0, tvOS 11.0, *) {
        renderer = UIGraphicsImageRenderer(bounds: bounds, format: .init(for: traits))
      } else {
        renderer = UIGraphicsImageRenderer(bounds: bounds)
      }
      return renderer
    }

    private func add(
      traits: UITraitCollection, viewController: UIViewController, to window: UIWindow
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
      rootViewController.setOverrideTraitCollection(traits, forChild: viewController)
      viewController.didMove(toParent: rootViewController)

      window.rootViewController = rootViewController

      rootViewController.beginAppearanceTransition(true, animated: false)
      rootViewController.endAppearanceTransition()

      rootViewController.view.setNeedsLayout()
      rootViewController.view.layoutIfNeeded()

      viewController.view.setNeedsLayout()
      viewController.view.layoutIfNeeded()

      return {
        rootViewController.beginAppearanceTransition(false, animated: false)
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
        viewController.didMove(toParent: nil)
        rootViewController.endAppearanceTransition()
        window.rootViewController = nil
      }
    }

    private func getKeyWindow() -> UIWindow? {
      var window: UIWindow?
      if #available(iOS 13.0, *) {
        window = UIApplication.sharedIfAvailable?.windows.first { $0.isKeyWindow }
      } else {
        window = UIApplication.sharedIfAvailable?.keyWindow
      }
      return window
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
