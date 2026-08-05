#if os(macOS)
import AppKit
import Snapshotting
import Testing

@MainActor
struct NSImageScaleTests {
  @Test func `a scale records that many pixels per point`() async throws {
    let image = drawingHandlerImage(points: 20)
    for scale in [CGFloat(1), 2, 3] {
      let recording = try await record(image, as: .image(scale: scale))
      #expect(recording.pixelsWide == Int(20 * scale))
      #expect(recording.pixelsHigh == Int(20 * scale))
      // The file carries the scale as its resolution, so it reads back at its size in points.
      #expect(recording.size == CGSize(width: 20, height: 20))
    }
  }

  /// Scaling an image that draws itself renders it again, rather than interpolating a smaller
  /// rendering of it, so detail below a point survives.
  @Test func `a scale resolves detail an image draws below a point`() async throws {
    let image = drawingHandlerImage(points: 3) { rect in
      NSColor.white.setFill()
      rect.fill()
      NSColor.black.setFill()
      NSBezierPath(rect: CGRect(x: 0, y: 0, width: 1.0 / 3.0, height: rect.height)).fill()
    }

    // A bar a third of a point wide can only be blended into the pixel it partly covers when a
    // point is one pixel, and is a pixel of its own when a point is three.
    let atOne = try await record(image, as: .image(scale: 1))
    let blended = try #require(atOne.white(x: 0, y: 1))
    #expect(blended > 0)
    #expect(blended < 1)

    let atThree = try await record(image, as: .image(scale: 3))
    #expect(atThree.white(x: 0, y: 4) == 0)
    #expect(atThree.white(x: 1, y: 4) == 1)
  }

  /// AppKit rasterizes an image that draws itself at the main display's backing scale factor, which
  /// is two on a Retina Mac and one on a machine with no display at all. The strategy decides
  /// instead, so that a reference does not belong to the Mac that recorded it.
  @Test func `an image that draws itself does not take its resolution from the display`() async throws {
    let image = drawingHandlerImage(points: 20)
    let recording = try await record(image, as: .image)
    #expect(recording.pixelsWide == Int(20 * SnapshotScale.default))
    #expect(recording.pixelsHigh == Int(20 * SnapshotScale.default))
  }

  /// The resolution a producer hands over is its own business — a screen's backing scale factor, or
  /// whichever representation of several AppKit reaches for. What is recorded is the strategy's.
  @Test func `a recording has the pixels the strategy names, not the ones it was handed`() async throws {
    for pixelsPerPoint in [CGFloat(1), 2, 4] {
      let recording = try await record(
        bitmapImage(points: 20, pixelsPerPoint: pixelsPerPoint),
        as: .image(scale: 2)
      )
      #expect(recording.pixelsWide == 40)
      #expect(recording.size == CGSize(width: 20, height: 20))
    }
  }

  @Test func `a scale resamples an image that has pixels`() async throws {
    let image = bitmapImage(points: 20, pixelsPerPoint: 2)
    #expect(try await record(image, as: .image(scale: 1)).pixelsWide == 20)
    #expect(try await record(image, as: .image(scale: 4)).pixelsWide == 80)
  }

  /// What the strategy would write to disk, read back the way a reference is.
  private func record(
    _ image: NSImage,
    as strategy: SnapshotStrategy<NSImage, NSImage>
  ) async throws -> NSBitmapImageRep {
    let data = try strategy.serializer.toData(try await strategy.snapshot(image))
    return try #require(NSBitmapImageRep(data: data))
  }

  /// An image with no pixels of its own, which draws whatever it is asked to draw at the size it is
  /// asked for.
  private func drawingHandlerImage(
    points: CGFloat,
    drawing: @escaping (CGRect) -> Void = {
      NSColor.red.setFill(); NSBezierPath(ovalIn: $0).fill()
    }
  ) -> NSImage {
    NSImage(size: CGSize(width: points, height: points), flipped: false) { rect in
      drawing(rect)
      return true
    }
  }

  private func bitmapImage(points: CGFloat, pixelsPerPoint: CGFloat) -> NSImage {
    let rep = NSBitmapImageRep(
      bitmapDataPlanes: nil,
      pixelsWide: Int(points * pixelsPerPoint),
      pixelsHigh: Int(points * pixelsPerPoint),
      bitsPerSample: 8,
      samplesPerPixel: 4,
      hasAlpha: true,
      isPlanar: false,
      colorSpaceName: .deviceRGB,
      bytesPerRow: 0,
      bitsPerPixel: 0
    )
    let size = CGSize(width: points, height: points)
    let image = NSImage(size: size)
    guard let rep else { return image }
    rep.size = size
    image.addRepresentation(rep)
    return image
  }
}

extension NSBitmapImageRep {
  fileprivate func white(x: Int, y: Int) -> CGFloat? {
    colorAt(x: x, y: y)?.usingColorSpace(.deviceGray)?.whiteComponent
  }
}
#endif
