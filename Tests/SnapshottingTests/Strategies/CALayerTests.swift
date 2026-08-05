#if canImport(AppKit) || canImport(UIKit)
import Snapshotting
import Testing

#if canImport(AppKit)
import AppKit
typealias XColor = NSColor
#elseif canImport(UIKit)
import UIKit
typealias XColor = UIColor
#endif

struct CALayerTests {
  @Test func `CALayer with colors`() async {
    let layer = CALayer()
    layer.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
    layer.backgroundColor = XColor.red.cgColor
    layer.borderWidth = 4.0
    layer.borderColor = XColor.black.cgColor
    await expectSnapshot(of: layer, as: .image)
  }

  @Test func `CALayer with gradient`() async {
    let baseLayer = CALayer()
    baseLayer.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
    let gradientLayer = CAGradientLayer()
    gradientLayer.colors = [XColor.red.cgColor, XColor.yellow.cgColor]
    gradientLayer.frame = baseLayer.frame
    baseLayer.addSublayer(gradientLayer)
    #if os(macOS)
    let name = platform
    #else
    let name = nil as String?
    #endif
    await expectSnapshot(of: baseLayer, as: .image, named: name)
  }

  #if canImport(AppKit)
  struct CALayerScaleTests {
    /// The layer is drawn at the scale the strategy was asked for, rather than at the scale of
    /// whatever display the machine running the test happens to have attached.
    @Test func `a layer rasterizes at the requested scale`() async throws {
      let image = try await snapshot(redLayer(width: 10, height: 10), scale: 2)

      #expect(image.size == NSSize(width: 10, height: 10))

      let rep = try NSBitmapImageRep(cgImage: pixels(of: image))
      #expect(rep.pixelsWide == 20)
      #expect(rep.pixelsHigh == 20)
    }

    /// The far corner is the one a mis-scaled context leaves behind, which is what makes it worth
    /// naming: the layer has to cover every pixel of the bitmap it is drawn into, not just the
    /// top-left quadrant of it.
    @Test func `a layer covers every pixel it is scaled up to`() async throws {
      let image = try await snapshot(redLayer(width: 10, height: 10), scale: 2)
      let rep = try NSBitmapImageRep(cgImage: pixels(of: image))

      for (x, y) in [(0, 0), (19, 0), (0, 19), (19, 19)] {
        #expect(try pixel(rep, x: x, y: y) == .red, "the pixel at (\(x),\(y)) should be red")
      }
    }

    /// A fractional bounds comes to a whole number of pixels, and the layer is stretched onto however
    /// many that turns out to be: drawing it at the scale it was asked for would leave the row and
    /// column the truncation paid for unpainted.
    @Test func `a layer with a fractional bounds covers the pixels it truncates to`() async throws {
      let image = try await snapshot(redLayer(width: 10.5, height: 10.5), scale: 2)
      let rep = try NSBitmapImageRep(cgImage: pixels(of: image))

      #expect(rep.pixelsWide == 21)
      #expect(rep.pixelsHigh == 21)

      #expect(try pixel(rep, x: 20, y: 20) == .red)
    }

    /// Coloured in the colorspace the strategy draws into, so that a pixel read back is the colour the
    /// layer was given rather than a conversion of it.
    private func redLayer(width: CGFloat, height: CGFloat) -> CALayer {
      let layer = CALayer()
      layer.frame = CGRect(x: 0, y: 0, width: width, height: height)
      layer.backgroundColor = CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1)
      return layer
    }

    private func snapshot(_ layer: CALayer, scale: CGFloat) async throws -> NSImage {
      try await SnapshotStrategy<CALayer, NSImage>.image(scale: scale).snapshot(layer)
    }

    private func pixels(of image: NSImage) throws -> CGImage {
      try #require(image.cgImage(forProposedRect: nil, context: nil, hints: nil))
    }

    /// Read as bytes rather than through `colorAt(x:y:)`, which hands back a component triple labelled
    /// Generic RGB whatever the bitmap is actually in — converting that to sRGB takes a pure red out of
    /// gamut and reports it as having green in it.
    private func pixel(_ rep: NSBitmapImageRep, x: Int, y: Int) throws -> Pixel {
      let bytes = try #require(rep.bitmapData)
      let offset = y * rep.bytesPerRow + x * (rep.bitsPerPixel / 8)
      return Pixel(
        red: bytes[offset],
        green: bytes[offset + 1],
        blue: bytes[offset + 2],
        alpha: bytes[offset + 3]
      )
    }
  }

  private struct Pixel: Equatable {
    let red: UInt8
    let green: UInt8
    let blue: UInt8
    let alpha: UInt8

    static let red = Pixel(red: 255, green: 0, blue: 0, alpha: 255)
  }
  #endif
}
#endif
