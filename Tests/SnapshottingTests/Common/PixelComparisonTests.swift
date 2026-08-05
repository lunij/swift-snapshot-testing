#if os(iOS) || os(macOS) || os(tvOS)
import CoreGraphics
import Testing

@testable import Snapshotting

/// Covers the decisions the image strategies delegate: what counts as a match, what the round trip
/// through the stored format is for, and what a precision below one tolerates. The strategies wrapping
/// it are covered by `UIImageDiffTests` and `NSImageDiffTests`.
struct PixelComparisonTests {
  @Test func `images of different dimensions are reported in pixels`() throws {
    let old = try #require(CGImage.grayscale(width: 4, height: 3) { _, _ in 0 })
    let new = try #require(CGImage.grayscale(width: 4, height: 5) { _, _ in 0 })

    let result = comparePixels(old, new, precision: 1, perceptualPrecision: 1) { new }

    guard case let .unequalSize(oldSize, newSize) = result else {
      Issue.record("Expected a size mismatch, got \(result)")
      return
    }
    #expect(oldSize == CGSize(width: 4, height: 3))
    #expect(newSize == CGSize(width: 4, height: 5))
  }

  /// The stored format is only reached for once the pixels in hand have already disagreed, so that a
  /// snapshot that matches costs nothing to encode.
  @Test func `equal pixels match without a round trip`() throws {
    let image = try #require(CGImage.grayscale(width: 4, height: 4) { _, _ in 128 })
    var reencoded = false

    let result = comparePixels(image, image, precision: 1, perceptualPrecision: 1) {
      reencoded = true
      return image
    }

    #expect(isMatching(result))
    #expect(!reencoded, "The round trip was taken for a snapshot that already matched")
  }

  /// Why the round trip is taken at all: the reference's pixels are what the encoder made of them, so
  /// a snapshot that only differs by what the encoding does to it is a match.
  @Test func `a difference the round trip accounts for is a match`() throws {
    let old = try #require(CGImage.grayscale(width: 4, height: 4) { _, _ in 128 })
    let new = try #require(CGImage.grayscale(width: 4, height: 4) { _, _ in 200 })

    let result = comparePixels(old, new, precision: 1, perceptualPrecision: 1) { old }

    #expect(isMatching(result))
  }

  @Test func `differing pixels do not match at full precision`() throws {
    let old = try #require(CGImage.grayscale(width: 4, height: 4) { _, _ in 0 })
    let new = try #require(CGImage.grayscale(width: 4, height: 4) { _, _ in 255 })

    let result = comparePixels(old, new, precision: 1, perceptualPrecision: 1) { new }

    guard case .isNotMatching = result else {
      Issue.record("Expected a mismatch, got \(result)")
      return
    }
  }

  /// A precision below one is a share of bytes, not of pixels: one differing pixel of a hundred moves
  /// three of the four hundred bytes, its alpha being equal either way.
  @Test func `a precision below one tolerates a share of the bytes`() throws {
    let old = try #require(CGImage.grayscale(width: 10, height: 10) { _, _ in 0 })
    let new = try #require(
      CGImage.grayscale(width: 10, height: 10) { x, y in x == 0 && y == 0 ? 255 : 0 }
    )

    let tolerant = comparePixels(old, new, precision: 0.99, perceptualPrecision: 1) { new }
    #expect(isMatching(tolerant))

    let strict = comparePixels(old, new, precision: 0.999, perceptualPrecision: 1) { new }
    guard case let .unmatchedPrecision(expected, actual) = strict else {
      Issue.record("Expected a precision mismatch, got \(strict)")
      return
    }
    #expect(expected == 0.999)
    #expect(abs(actual - 0.9925) < 0.0001, "Expected 397 of 400 bytes to be equal, got \(actual)")
  }

  @Test func `a snapshot that will not survive the round trip is a failure`() throws {
    let old = try #require(CGImage.grayscale(width: 4, height: 4) { _, _ in 0 })
    let new = try #require(CGImage.grayscale(width: 4, height: 4) { _, _ in 255 })

    let result = comparePixels(old, new, precision: 1, perceptualPrecision: 1) { nil }

    guard case .cgContextDataConversionFailed = result else {
      Issue.record("Expected a Core Graphics failure, got \(result)")
      return
    }
  }

  /// The bytes are subtracted by offset, so a round trip that comes back a different size cannot be
  /// compared at all — reported rather than read past the end of.
  @Test func `a round trip that changes the pixel count is a failure`() throws {
    let old = try #require(CGImage.grayscale(width: 4, height: 4) { _, _ in 0 })
    let new = try #require(CGImage.grayscale(width: 4, height: 4) { _, _ in 255 })
    let resized = try #require(CGImage.grayscale(width: 4, height: 5) { _, _ in 255 })

    let result = comparePixels(old, new, precision: 1, perceptualPrecision: 1) { resized }

    guard case .cgContextDataConversionFailed = result else {
      Issue.record("Expected a Core Graphics failure, got \(result)")
      return
    }
  }

  private func isMatching(_ result: ImageComparisonResult) -> Bool {
    if case .isMatching = result { return true }
    return false
  }
}
#endif
