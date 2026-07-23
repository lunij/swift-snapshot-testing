#if os(macOS)
import AppKit
import Testing
@testable import SnapshotTesting

extension BaseSuite {
  struct NSViewScaleTests {
    /// Verifies that `convertToImage(scale:2)` produces a 20×20-pixel image
    /// with a 10×10-point logical size, and that all four corners contain the
    /// expected color — including the far corner (19, 19) which was
    /// transparent under the old dead-`scaleBy` bug.
    @Test @MainActor func convertToImageScale2RendersEntireView() throws {
      let view = NSView(frame: NSRect(x: 0, y: 0, width: 10, height: 10))
      view.wantsLayer = true
      view.layer?.backgroundColor = NSColor(red: 0, green: 1, blue: 0, alpha: 1).cgColor

      let image = view.convertToImage(scale: 2)

      #expect(image.size == NSSize(width: 10, height: 10))

      let rep = try #require(
        image.representations.compactMap { $0 as? NSBitmapImageRep }.first
      )
      #expect(rep.pixelsWide == 20)
      #expect(rep.pixelsHigh == 20)

      for (x, y) in [(0, 0), (19, 0), (0, 19), (19, 19)] {
        let color = try #require(rep.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB))
        #expect(color.redComponent < 0.1, "red at (\(x),\(y)) should be ~0")
        #expect(color.greenComponent > 0.9, "green at (\(x),\(y)) should be ~1")
        #expect(color.blueComponent < 0.1, "blue at (\(x),\(y)) should be ~0")
        #expect(color.alphaComponent > 0.9, "alpha at (\(x),\(y)) should be ~1")
      }
    }
  }
}
#endif
