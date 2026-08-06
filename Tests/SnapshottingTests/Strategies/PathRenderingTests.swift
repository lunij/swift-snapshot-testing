#if os(iOS) || os(macOS) || os(tvOS)
import CoreGraphics
import Testing

#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

@testable import Snapshotting

/// Covers the rendering every path strategy shares: where a path lands on the canvas it is drawn
/// into, how many pixels it comes to, and which of the interior a drawing mode paints. What each
/// strategy then records is covered by `BezierPathTests`.
struct PathRenderingTests {
  /// The path is moved onto the canvas rather than the canvas grown to reach it, so where a path
  /// happens to sit is not something its recording can tell you.
  @Test func `a path away from the origin records what it would at it`() throws {
    var displacement = CGAffineTransform(translationX: 250, y: -80)
    let moved = try #require(CGPath.heart.copy(using: &displacement))
    #expect(moved.boundingBoxOfPath.origin == CGPoint(x: 250, y: -80))

    let atOrigin = try pixels(of: CGPath.heart.convertToImage(drawingMode: .eoFill, scale: 1, origin: .bottomLeft))
    let awayFromIt = try pixels(of: moved.convertToImage(drawingMode: .eoFill, scale: 1, origin: .bottomLeft))

    #expect(awayFromIt.bytes == atOrigin.bytes)
  }

  /// An empty path encloses nothing, so its bounding box is null and the canvas refuses it. Worth
  /// stating, because reading the size off a null rectangle is what a recording does before it can
  /// discover there is nothing to record.
  @Test func `a path enclosing nothing is refused`() {
    #expect(throws: ImageConversionError.zeroSize) {
      try CGMutablePath().convertToImage(drawingMode: .eoFill, scale: 1, origin: .bottomLeft)
    }
  }

  @Test(arguments: [CGFloat(1), 2, 3])
  func `a scale records that many pixels per point`(scale: CGFloat) throws {
    // The heart measures 90 points on a side.
    let recording = try pixels(of: CGPath.heart.convertToImage(drawingMode: .eoFill, scale: scale, origin: .bottomLeft))

    #expect(recording.width == Int(90 * scale))
    #expect(recording.height == Int(90 * scale))
  }

  /// The corner is named by whatever authored the path rather than taken from the platform, so both
  /// answers have to be available on all of them — and the one is the other turned over.
  @Test func `the origin corner turns the recording over`() throws {
    let fromBottom = try pixels(
      of: CGPath.heart.convertToImage(drawingMode: .eoFill, scale: 1, origin: .bottomLeft)
    )
    let fromTop = try pixels(
      of: CGPath.heart.convertToImage(drawingMode: .eoFill, scale: 1, origin: .topLeft)
    )

    #expect(fromTop.width == fromBottom.width)
    #expect(fromTop.height == fromBottom.height)
    #expect(fromTop.bytes != fromBottom.bytes, "the heart is not symmetrical about its middle row")

    // Turning the picture over is exact for a pixel a path either covers or does not, and rounds the
    // other way for one it half covers, so a mirrored row is the same row to within a single value
    // of a byte rather than byte for byte.
    var largestDifference = 0
    for y in 0..<fromTop.height {
      let against = fromBottom.row(fromBottom.height - 1 - y)
      largestDifference = max(
        largestDifference,
        zip(fromTop.row(y), against).map { abs(Int($0) - Int($1)) }.max() ?? 0
      )
    }
    #expect(largestDifference <= 1)
  }

  /// The drawing mode decides what counts as the interior where a path covers itself: even-odd counts
  /// the crossings, which puts the square the two share outside the path, and non-zero fills it.
  @Test func `even-odd leaves an overlap that non-zero fills`() throws {
    let evenOdd = try pixels(of: overlappingSquares.convertToImage(drawingMode: .eoFill, scale: 1, origin: .bottomLeft))
    let nonZero = try pixels(of: overlappingSquares.convertToImage(drawingMode: .fill, scale: 1, origin: .bottomLeft))

    #expect(evenOdd.alpha(x: 15, y: 15) == 0)
    #expect(nonZero.alpha(x: 15, y: 15) == 255)
  }

  /// A bezier path carries a rule of its own for filling itself, which the recording reads off the
  /// value rather than fixing when the strategy is built.
  @Test func `a bezier path fills by its own rule`() async throws {
    #if os(macOS)
    let evenOdd = NSBezierPath(cgPath: overlappingSquares)
    evenOdd.windingRule = .evenOdd
    let nonZero = NSBezierPath(cgPath: overlappingSquares)
    nonZero.windingRule = .nonZero
    let strategy = SnapshotStrategy<NSBezierPath, NSImage>.image
    #else
    let evenOdd = UIBezierPath(cgPath: overlappingSquares)
    evenOdd.usesEvenOddFillRule = true
    let nonZero = UIBezierPath(cgPath: overlappingSquares)
    nonZero.usesEvenOddFillRule = false
    let strategy = SnapshotStrategy<UIBezierPath, UIImage>.image
    #endif

    #expect(try await pixels(of: strategy.snapshot(evenOdd)).alpha(x: 15, y: 15) == 0)
    #expect(try await pixels(of: strategy.snapshot(nonZero)).alpha(x: 15, y: 15) == 255)
  }

  /// Two squares overlapping in a square of their own, centred on the path's bounding box so that the
  /// middle pixel is inside the overlap whichever corner the origin is in.
  private var overlappingSquares: CGPath {
    let path = CGMutablePath()
    path.addRect(CGRect(x: 0, y: 0, width: 20, height: 20))
    path.addRect(CGRect(x: 10, y: 10, width: 20, height: 20))
    return path
  }

  /// The pixels a recording carries, whichever platform's image it came back as.
  private func pixels(of image: XImage) throws -> PixelBuffer {
    #if os(macOS)
    let cgImage = try #require(image.cgImage(forProposedRect: nil, context: nil, hints: nil))
    #else
    let cgImage = try #require(image.cgImage)
    #endif
    return try #require(PixelBuffer(cgImage))
  }
}

extension PixelBuffer {
  /// How opaque the pixel at a coordinate is, rows counted from the top.
  fileprivate func alpha(x: Int, y: Int) -> UInt8 {
    bytes[(y * width + x) * PixelLayout.bytesPerPixel + 3]
  }

  /// A row of pixels, counted from the top.
  fileprivate func row(_ y: Int) -> ArraySlice<UInt8> {
    let bytesPerRow = width * PixelLayout.bytesPerPixel
    return bytes[(y * bytesPerRow)..<((y + 1) * bytesPerRow)]
  }
}
#endif
