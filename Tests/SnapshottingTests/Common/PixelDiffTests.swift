#if os(iOS) || os(macOS) || os(tvOS)
import CoreGraphics
import Testing

@testable import Snapshotting

/// Covers what the artifact a failure carries is meant to show: where two images differ, and how far
/// apart they are there. The strategies wrapping it are covered by `UIImageDiffTests` and
/// `NSImageDiffTests`.
struct PixelDiffTests {
  @Test func `the diff covers the images pixel for pixel`() throws {
    let old = try #require(CGImage.grayscale(width: 101, height: 3) { _, _ in 0 })
    let new = try #require(CGImage.grayscale(width: 101, height: 3) { x, _ in x == 0 ? 255 : 0 })

    let diff = try #require(normalizedComponentDiff(old, new))

    #expect(diff.width == 101)
    #expect(diff.height == 3)
  }

  /// Subtracting pixels needs a pixel to subtract from. Nothing here can say what a diff of images of
  /// different sizes would even mean, so the caller is handed the question back.
  @Test func `images of different dimensions have no diff`() throws {
    let old = try #require(CGImage.grayscale(width: 4, height: 3) { _, _ in 0 })
    let new = try #require(CGImage.grayscale(width: 4, height: 5) { _, _ in 0 })

    #expect(normalizedComponentDiff(old, new) == nil)
  }

  @Test func `where the images agree the diff is black`() throws {
    let old = try #require(CGImage.grayscale(width: 4, height: 4) { _, _ in 128 })
    let new = try #require(CGImage.grayscale(width: 4, height: 4) { x, _ in x == 0 ? 255 : 128 })

    let diff = try #require(normalizedComponentDiff(old, new))

    #expect(try grayValue(of: diff, atX: 1, y: 0) == 0)
    #expect(try grayValue(of: diff, atX: 3, y: 3) == 0)
  }

  /// What the normalizing is for: differences of two components out of 255 are black to the eye, and
  /// a diff that shows them nowhere is a diff that shows nothing. The largest difference in the image
  /// is brightened to white however small it is, and the rest of them in proportion.
  @Test func `the largest difference is white however small it is`() throws {
    let old = try #require(CGImage.grayscale(width: 4, height: 1) { _, _ in 10 })
    let new = try #require(
      CGImage.grayscale(width: 4, height: 1) { x, _ in
        switch x {
        case 0: 12
        case 1: 11
        default: 10
        }
      }
    )

    let diff = try #require(normalizedComponentDiff(old, new))

    #expect(try grayValue(of: diff, atX: 0, y: 0) == 255)
    let halfway = try grayValue(of: diff, atX: 1, y: 0)
    #expect(halfway > 0 && halfway < 255, "A difference of one of two came out \(halfway)")
    #expect(try grayValue(of: diff, atX: 3, y: 0) == 0)
  }

  /// A pixel is as different as its furthest-apart component, not as different as its components are
  /// on average: a color that moved in one channel alone is a difference worth seeing, and so is one
  /// that only moved in alpha.
  @Test func `a pixel's difference is the largest its components move`() throws {
    let old = try #require(
      CGImage.rgba(width: 3, height: 1) { _, _ in (red: 0, green: 0, blue: 0, alpha: 255) }
    )
    let new = try #require(
      CGImage.rgba(width: 3, height: 1) { x, _ in
        switch x {
        case 0: (red: 0, green: 0, blue: 10, alpha: 255)
        case 1: (red: 0, green: 0, blue: 0, alpha: 247)
        default: (red: 5, green: 5, blue: 5, alpha: 255)
        }
      }
    )

    let diff = try #require(normalizedComponentDiff(old, new))

    let oneChannel = try grayValue(of: diff, atX: 0, y: 0)
    let alphaOnly = try grayValue(of: diff, atX: 1, y: 0)
    let everyChannel = try grayValue(of: diff, atX: 2, y: 0)
    #expect(
      oneChannel > alphaOnly && alphaOnly > everyChannel,
      """
      Expected the pixels to be ordered by their largest moving component — 10, then 8, then 5 — \
      got \(oneChannel), \(alphaOnly), \(everyChannel)
      """
    )
  }

  /// Images that do line up are diffed component by component, so a difference of two out of 255 is
  /// stretched to white rather than left invisible — which is what tells the two diffs apart.
  @Test func `images that line up are diffed component by component`() throws {
    let old = try #require(CGImage.grayscale(width: 4, height: 1) { _, _ in 10 })
    let new = try #require(CGImage.grayscale(width: 4, height: 1) { x, _ in x == 0 ? 12 : 10 })

    let diff = try #require(pixelDiff(old, new))

    #expect(try grayValue(of: diff, atX: 0, y: 0) == 255)
  }

  @Test func `a size mismatch is diffed on a canvas that covers both images`() throws {
    let old = try #require(CGImage.grayscale(width: 10, height: 10) { _, _ in 200 })
    let new = try #require(CGImage.grayscale(width: 4, height: 4) { _, _ in 200 })

    let diff = try #require(pixelDiff(old, new))

    #expect(diff.width == 10)
    #expect(diff.height == 10)
  }

  /// Every pixel only one of the two images reaches is that image's own, so a size mismatch reads as
  /// the region the smaller of them leaves behind. The two agree everywhere they overlap here, which
  /// leaves the pixels the larger one covers alone as the only ones that are not black.
  @Test func `the region only one image covers is that image`() throws {
    let old = try #require(CGImage.grayscale(width: 10, height: 10) { _, _ in 200 })
    let new = try #require(CGImage.grayscale(width: 4, height: 4) { _, _ in 200 })

    let diff = try #require(pixelDiff(old, new))
    let buffer = try #require(PixelBuffer(diff))
    let litPixels = (0..<buffer.pixelCount).count { pixel in
      buffer.bytes[pixel * PixelLayout.bytesPerPixel] > 0
    }

    #expect(litPixels == 10 * 10 - 4 * 4)
  }

  /// The diff is grayscale, so its red channel is the brightness of a pixel. Reading it back through
  /// a `PixelBuffer` converts it to sRGB, which moves the values it does not clamp; only their order
  /// and the ends of the range mean anything.
  private func grayValue(of diff: CGImage, atX x: Int, y: Int) throws -> UInt8 {
    let buffer = try #require(PixelBuffer(diff))
    return buffer.bytes[(y * buffer.width + x) * PixelLayout.bytesPerPixel]
  }
}
#endif
