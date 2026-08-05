#if os(iOS) || os(macOS) || os(tvOS)
import CoreGraphics
import CoreImage

/// Whether two images carry the same pixels, to a precision.
///
/// - Parameters:
///   - old: The reference's pixels.
///   - new: The snapshot's pixels.
///   - precision: The share of bytes that have to be equal for the two to count as matching.
///   - perceptualPrecision: How close a pixel has to be to its counterpart to count as equal. Below
///     `1` the comparison is handed to ``perceptuallyCompare(_:_:pixelPrecision:perceptualPrecision:)``,
///     which reads colors rather than bytes.
///   - reencodedNew: The snapshot's pixels after a round trip through the format it is stored in, or
///     `nil` when it will not survive one. Only asked for once the bytes have already disagreed.
func comparePixels(
  _ old: CGImage,
  _ new: CGImage,
  precision: Float,
  perceptualPrecision: Float,
  reencodedNew: () throws -> CGImage?
) rethrows -> ImageComparisonResult {
  guard old.width == new.width, old.height == new.height else {
    return .unequalSize(old: old.size, new: new.size)
  }
  guard let oldBuffer = PixelBuffer(old) else {
    return .cgContextDataConversionFailed
  }
  if let newBuffer = PixelBuffer(new), oldBuffer.bytes == newBuffer.bytes {
    return .isMatching
  }

  // The reference was read back from a file, so its pixels are whatever the encoder made of them.
  // Putting the snapshot through the same round trip is what stops a difference the file format
  // introduces — a color profile it does not carry, a component it rounds — from being reported as a
  // difference between the two images.
  guard
    let reencoded = try reencodedNew(),
    let reencodedBuffer = PixelBuffer(reencoded),
    reencodedBuffer.byteCount == oldBuffer.byteCount
  else {
    return .cgContextDataConversionFailed
  }
  if oldBuffer.bytes == reencodedBuffer.bytes {
    return .isMatching
  }

  if precision >= 1, perceptualPrecision >= 1 {
    return .isNotMatching
  }
  if perceptualPrecision < 1 {
    return perceptuallyCompare(
      CIImage(cgImage: old),
      CIImage(cgImage: new),
      pixelPrecision: precision,
      perceptualPrecision: perceptualPrecision
    )
  }

  let byteCount = oldBuffer.byteCount
  let differingByteCount = oldBuffer.differingByteCount(from: reencodedBuffer)
  guard differingByteCount > Int((1 - precision) * Float(byteCount)) else {
    return .isMatching
  }
  return .unmatchedPrecision(
    expected: precision,
    actual: 1 - Float(differingByteCount) / Float(byteCount)
  )
}

extension PixelBuffer {
  /// The bytes this buffer and another one disagree on, the two covering the same pixels.
  fileprivate func differingByteCount(from other: PixelBuffer) -> Int {
    var count = 0
    // NB: We are purposely using a verbose 'while' loop instead of a 'for in' loop.  When the
    //     compiler doesn't have optimizations enabled, a `while` loop is
    //     significantly faster than a `for` loop for iterating through the elements of a memory
    //     buffer. Details can be found in [SR-6983](https://github.com/apple/swift/issues/49531)
    var index = 0
    while index < byteCount {
      defer { index += 1 }
      if bytes[index] != other.bytes[index] {
        count += 1
      }
    }
    return count
  }
}
#endif
