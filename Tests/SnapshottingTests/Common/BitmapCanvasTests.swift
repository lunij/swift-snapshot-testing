#if os(iOS) || os(macOS) || os(tvOS)
import CoreGraphics
import Testing

@testable import Snapshotting

/// Covers the bitmap the platform strategies draw their recordings into: how many pixels a size in
/// points comes to, that drawing in points reaches all of them, and which empty sizes are refused.
/// What each platform then draws into it is covered by `CALayerTests` and `NSImageTests`.
struct BitmapCanvasTests {
  @Test func `a canvas takes its pixels from the size and the scale`() throws {
    let canvas = try BitmapCanvas(size: CGSize(width: 10, height: 4), scale: 2)

    #expect(canvas.pixelsWide == 20)
    #expect(canvas.pixelsHigh == 8)
    #expect(canvas.size == CGSize(width: 10, height: 4))

    let cgImage = try canvas.makeImage()
    #expect(cgImage.width == 20)
    #expect(cgImage.height == 8)
  }

  /// A renderer draws a fractional length into a whole number of pixels, so the canvas has to agree
  /// with it: a snapshot sized anywhere in between would be resampled onto a size nothing drew at.
  @Test func `a fractional size truncates to whole pixels`() throws {
    let canvas = try BitmapCanvas(size: CGSize(width: 10.75, height: 4.5), scale: 1)

    #expect(canvas.pixelsWide == 10)
    #expect(canvas.pixelsHigh == 4)
  }

  /// The guarantee everything drawing into a canvas rests on: a rectangle covering the size in points
  /// paints every pixel, including the last row and column that a canvas scaled by the scale itself
  /// would leave behind.
  @Test func `a rectangle covering the size in points paints every pixel`() throws {
    let canvas = try BitmapCanvas(size: CGSize(width: 10.75, height: 4.5), scale: 1)
    canvas.context.setFillColor(gray: 1, alpha: 1)
    canvas.context.fill(CGRect(origin: .zero, size: canvas.size))

    let buffer = try #require(PixelBuffer(try canvas.makeImage()))

    let unpainted = (0..<buffer.byteCount).filter { buffer.bytes[$0] != 255 }
    #expect(unpainted.isEmpty, "\(unpainted.count) of \(buffer.byteCount) bytes were left unpainted")
  }

  @Test func `a canvas of named pixels stretches the size over them`() throws {
    let canvas = try BitmapCanvas(size: CGSize(width: 10, height: 4), pixelsWide: 3, pixelsHigh: 30)

    #expect(canvas.pixelsWide == 3)
    #expect(canvas.pixelsHigh == 30)
    #expect(canvas.size == CGSize(width: 10, height: 4))
  }

  /// An empty size is reported as such rather than as one of its dimensions, and a single empty
  /// dimension is named.
  @Test(arguments: [
    (CGSize.zero, ImageConversionError.zeroSize),
    (CGSize(width: 0, height: 10), ImageConversionError.zeroWidth),
    (CGSize(width: 10, height: 0), ImageConversionError.zeroHeight)
  ])
  func `a size with no extent is refused`(size: CGSize, error: ImageConversionError) {
    #expect(throws: error) {
      try BitmapCanvas(size: size, scale: 1)
    }
  }

  /// A size that has an extent but comes to no pixels is not an empty snapshot, it is a scale nothing
  /// can be drawn at.
  @Test func `a scale that comes to no pixels is refused`() {
    #expect(throws: ImageConversionError.cgImageConversionFailed) {
      try BitmapCanvas(size: CGSize(width: 2, height: 2), scale: 0.25)
    }
  }
}
#endif
