#if os(iOS) || os(tvOS)
import SnapshotTesting
import Testing
import UIKit

@Suite(.snapshots(record: .failed, diffTool: .ksdiff))
struct UIImageDiffTests {
  /// The diff artifact must be correct regardless of the pixel format ImageIO chooses when
  /// decoding the reference. A grayscale PNG decodes to an 8-bits-per-pixel `CGImage`, and an
  /// odd width additionally forces row padding, so this covers the layouts that raw RGBA8888
  /// indexing mishandles.
  @Test func diffArtifactFromGrayscaleReference() throws {
    let width = 101
    let height = 50

    // Right half differs; left half matches. A vertical split keeps the assertions
    // independent of row order in bitmap buffers.
    let old = try grayscalePNGImage(width: width, height: height) { _, _ in 100 }
    let new = try grayscalePNGImage(width: width, height: height) { x, _ in
      x >= 51 ? 200 : 100
    }

    let oldCgImage = try #require(old.cgImage)
    try #require(
      oldCgImage.bitsPerPixel < 32,
      "Precondition failed: the reference must decode to a sub-32bpp image to reproduce"
    )

    let failure = try #require(try SnapshotComparator<UIImage>.image.diff(old, new))
    let diffData = try #require(
      failure.artifacts.compactMap { artifact -> Data? in
        guard artifact.name == "diff" else { return nil }
        return artifact.data
      }.first
    )
    let diffImage = try #require(UIImage(data: diffData))

    #expect(diffImage.cgImage?.width == width)
    #expect(diffImage.cgImage?.height == height)

    // The contrast-stretched diff must be black where the images match and white where
    // they differ.
    let matchingValue = try #require(grayValue(of: diffImage, atX: 10, y: 25))
    let differingValue = try #require(grayValue(of: diffImage, atX: 90, y: 25))
    #expect(matchingValue < 10)
    #expect(differingValue > 200)
  }

  /// Builds a `UIImage` backed by ImageIO's native decode of a grayscale PNG, like a reference
  /// image loaded from disk by `SnapshotSerializer.fromData`.
  private func grayscalePNGImage(
    width: Int,
    height: Int,
    value: (_ x: Int, _ y: Int) -> UInt8
  ) throws -> UIImage {
    var bytes = [UInt8](repeating: 0, count: width * height)
    for y in 0..<height {
      for x in 0..<width {
        bytes[y * width + x] = value(x, y)
      }
    }
    let cgImage = try bytes.withUnsafeMutableBytes { pointer -> CGImage in
      let context = try #require(
        CGContext(
          data: pointer.baseAddress,
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
    let pngData = try #require(UIImage(cgImage: cgImage).pngData())
    return try #require(UIImage(data: pngData))
  }

  private func grayValue(of image: UIImage, atX x: Int, y: Int) -> UInt8? {
    guard let cgImage = image.cgImage else { return nil }
    let width = cgImage.width
    let height = cgImage.height
    var bytes = [UInt8](repeating: 0, count: width * height)
    return bytes.withUnsafeMutableBytes { pointer in
      guard
        let context = CGContext(
          data: pointer.baseAddress,
          width: width,
          height: height,
          bitsPerComponent: 8,
          bytesPerRow: width,
          space: CGColorSpaceCreateDeviceGray(),
          bitmapInfo: CGImageAlphaInfo.none.rawValue
        )
      else { return nil }
      context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
      return pointer[y * width + x]
    }
  }
}
#endif
