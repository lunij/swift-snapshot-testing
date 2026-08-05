#if os(iOS) || os(macOS) || os(tvOS)
import CoreGraphics
import Testing

@testable import Snapshotting

/// Covers the one guarantee everything comparing images rests on: that whatever layout an image
/// arrived in, its bytes come back tightly packed, four to a pixel, in a known order. The strategies
/// that read those bytes are covered by `UIImageDiffTests` and `NSImageDiffTests`.
struct PixelBufferTests {
  @Test func `a buffer takes its dimensions from the image`() throws {
    let cgImage = try #require(CGImage.grayscale(width: 101, height: 3) { _, _ in 0 })
    let buffer = try #require(PixelBuffer(cgImage))

    #expect(buffer.width == 101)
    #expect(buffer.height == 3)
    #expect(buffer.pixelCount == 303)
  }

  /// A source that is neither RGBA nor free of row padding — one component a pixel, and an odd width
  /// that ImageIO pads out — still yields four bytes a pixel with nothing between rows.
  @Test func `a grayscale image is repacked as four bytes a pixel`() throws {
    let width = 101
    let height = 3
    let cgImage = try #require(CGImage.grayscale(width: width, height: height) { _, _ in 128 })
    try #require(
      cgImage.bitsPerPixel < 32,
      "Precondition failed: the source must carry fewer than four bytes a pixel to be repacked"
    )

    let buffer = try #require(PixelBuffer(cgImage))

    #expect(buffer.byteCount == width * height * 4)
    // Every pixel is opaque mid-gray, so each is the same four bytes wherever it sits. Reading the
    // last pixel of the first row is what catches padding: a padded row would put something else at
    // that offset.
    let lastPixelOfFirstRow = (width - 1) * 4
    #expect(Array(buffer.bytes[lastPixelOfFirstRow..<lastPixelOfFirstRow + 4]) == [128, 128, 128, 255])
  }

  /// The bytes of a pixel are addressed by row and column, which is what lets the comparison report a
  /// count of differing bytes and the diff paint them in the right place.
  @Test func `a pixel's bytes sit where its coordinates say`() throws {
    let width = 5
    let height = 4
    // Distinct per row and column, so a transposed or bottom-up reading cannot pass.
    let cgImage = try #require(
      CGImage.grayscale(width: width, height: height) { x, y in UInt8(16 * y + x) }
    )

    let buffer = try #require(PixelBuffer(cgImage))

    for y in 0..<height {
      for x in 0..<width {
        let offset = (y * width + x) * PixelLayout.bytesPerPixel
        #expect(buffer.bytes[offset] == UInt8(16 * y + x), "red at (\(x), \(y))")
        #expect(buffer.bytes[offset + 3] == 255, "alpha at (\(x), \(y))")
      }
    }
  }

  @Test func `a row of pixels is packed tight`() {
    #expect(PixelLayout.bytesPerRow(width: 101) == 404)
  }
}
#endif
