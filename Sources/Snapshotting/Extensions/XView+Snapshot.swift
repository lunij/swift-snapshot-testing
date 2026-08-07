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
        // A view with no scene presented, or one whose contents cannot be read
        // back as a texture, has nothing to capture.
        guard let cgImage = inWindow({ skView.scene.flatMap { skView.texture(from: $0)?.cgImage() } })
        else { return nil }
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
}
#endif
