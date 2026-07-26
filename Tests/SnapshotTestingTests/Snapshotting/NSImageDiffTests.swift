#if os(macOS)
import AppKit
import SnapshotTesting
import Testing

@Suite(.snapshots(record: .failed, diffTool: .ksdiff))
struct NSImageDiffTests {
  /// The precision comparison must give correct pass/fail results regardless of the pixel format
  /// ImageIO chooses when decoding the reference. A grayscale PNG decodes to an 8-bits-per-pixel
  /// CGImage, and an odd width additionally forces row padding, so this covers the layouts that
  /// comparing raw NSBitmapImageRep.bitmapData bytes against a CGContext-derived byte count
  /// mishandles.
  @Test func precisionComparisonWithGrayscaleSource() throws {
    let width = 101  // odd width forces row padding in a grayscale CGImage
    let height = 50

    // Right half differs; left half matches.
    let old = try grayscaleNSImage(width: width, height: height) { _, _ in 128 }
    let new = try grayscaleNSImage(width: width, height: height) { x, _ in
      x >= 51 ? 200 : 128
    }

    let oldCgImage = try #require(old.cgImage(forProposedRect: nil, context: nil, hints: nil))
    try #require(
      oldCgImage.bitsPerPixel < 32,
      "Precondition failed: the reference must decode to a sub-32bpp image to reproduce the layout mismatch"
    )

    // 50/101 columns differ. Each differing pixel contributes 3 changed bytes (R,G,B) and 1
    // unchanged (A=255), giving ~37% byte mismatch. precision=0.4 allows 60% → passes.
    let shouldPass = try Diffing<NSImage>.image(precision: 0.4, perceptualPrecision: 1)
      .diff(old, new)
    #expect(shouldPass == nil)

    // ~37% byte mismatch. precision=0.7 allows only 30% → fails.
    let shouldFail = try Diffing<NSImage>.image(precision: 0.7, perceptualPrecision: 1)
      .diff(old, new)
    #expect(shouldFail != nil)
  }

  /// Builds an NSImage backed by ImageIO's native decode of a grayscale PNG, matching how
  /// reference images are loaded from disk by Diffing.fromData.
  private func grayscaleNSImage(
    width: Int,
    height: Int,
    value: (_ x: Int, _ y: Int) -> UInt8
  ) throws -> NSImage {
    var bytes = [UInt8](repeating: 0, count: width * height)
    for y in 0..<height {
      for x in 0..<width {
        bytes[y * width + x] = value(x, y)
      }
    }
    let cgImage = try bytes.withUnsafeMutableBytes { ptr -> CGImage in
      let context = try #require(
        CGContext(
          data: ptr.baseAddress,
          width: width,
          height: height,
          bitsPerComponent: 8,
          bytesPerRow: width,
          space: CGColorSpaceCreateDeviceGray(),
          bitmapInfo: CGImageAlphaInfo.none.rawValue
        )
      )
      return try #require(context.makeImage())
    }
    let rep = NSBitmapImageRep(cgImage: cgImage)
    rep.size = NSSize(width: width, height: height)
    let pngData = try #require(rep.representation(using: .png, properties: [:]))
    return try #require(NSImage(data: pngData))
  }
}
#endif
