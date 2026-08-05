#if os(iOS) || os(macOS) || os(tvOS)
import Accelerate.vImage
import CoreGraphics

/// Where two images differ, as an image.
///
/// - Returns: `nil` when Core Graphics will not hand the images' bytes over, which leaves a mismatch
///   reported without a picture of it.
func pixelDiff(_ old: CGImage, _ new: CGImage) -> CGImage? {
  normalizedComponentDiff(old, new) ?? blendModeDiff(old, new)
}

/// Where two images differ, as a grayscale image: black where they agree, and brighter the further
/// apart they are.
///
/// A pixel's difference is the largest any one of its four components moves by, brightened afterwards
/// so that the largest difference in the image comes out white. Without that stretch a diff would
/// only be readable where a snapshot changed wholesale: the differences worth looking at — an edge
/// that shifted, a color that drifted — are a component or two apart, which is black to the eye.
///
/// - Returns: `nil` when the two images do not cover the same pixels, one with no extent among them,
///   or when Core Graphics will not hand their bytes over. A difference taken by subtracting pixels
///   has nothing to say about images of different sizes, so the caller is expected to have a diff
///   that does.
func normalizedComponentDiff(_ old: CGImage, _ new: CGImage) -> CGImage? {
  guard
    old.width == new.width,
    old.height == new.height,
    old.width > 0,
    old.height > 0,
    let oldBuffer = PixelBuffer(old),
    let newBuffer = PixelBuffer(new)
  else {
    return nil
  }

  let pixelCount = oldBuffer.pixelCount
  var diffBytes = [UInt8](repeating: 0, count: pixelCount)

  // NB: We are purposely using a verbose 'while' loop instead of a 'for in' loop.  When the
  //     compiler doesn't have optimizations enabled, a `while` loop is
  //     significantly faster than a `for` loop for iterating through the elements of a memory
  //     buffer. Details can be found in [SR-6983](https://github.com/apple/swift/issues/49531)
  var index = 0
  while index < pixelCount {
    defer { index += 1 }
    let pixelOffset = index * PixelLayout.bytesPerPixel
    let rDiff = abs(Int16(oldBuffer.bytes[pixelOffset]) - Int16(newBuffer.bytes[pixelOffset]))
    let gDiff = abs(Int16(oldBuffer.bytes[pixelOffset + 1]) - Int16(newBuffer.bytes[pixelOffset + 1]))
    let bDiff = abs(Int16(oldBuffer.bytes[pixelOffset + 2]) - Int16(newBuffer.bytes[pixelOffset + 2]))
    let aDiff = abs(Int16(oldBuffer.bytes[pixelOffset + 3]) - Int16(newBuffer.bytes[pixelOffset + 3]))
    diffBytes[index] = UInt8(max(rDiff, gDiff, bDiff, aDiff))
  }

  return brightened(diffBytes, width: oldBuffer.width, height: oldBuffer.height)
}

/// Where two images differ, for a pair whose pixels do not line up, by drawing one over the other in
/// difference blend mode.
///
/// The canvas covers both images, and each of them is drawn at the pixels it carries, so a size
/// mismatch shows up as the region only one of them reaches: subtracting nothing from a pixel leaves
/// that pixel, which is the image that covers it.
///
/// - Returns: `nil` when there are no pixels to cover, or when Core Graphics will not give up a
///   canvas of this layout.
func blendModeDiff(_ old: CGImage, _ new: CGImage) -> CGImage? {
  let pixelsWide = max(old.width, new.width)
  let pixelsHigh = max(old.height, new.height)
  guard let context = PixelLayout.context(width: pixelsWide, height: pixelsHigh) else {
    return nil
  }

  context.draw(new, in: CGRect(origin: .zero, size: new.size))
  context.setBlendMode(.difference)
  context.draw(old, in: CGRect(origin: .zero, size: old.size))

  return context.makeImage()
}

/// One byte a pixel, stretched over the whole range of brightness, as a grayscale image.
///
/// The bytes are handed over as they stand when the stretch fails, brightness being a courtesy: a
/// diff that is hard to read still says where the two images differ.
private func brightened(_ bytes: [UInt8], width: Int, height: Int) -> CGImage? {
  guard
    let colorSpace = CGColorSpace(name: CGColorSpace.linearGray),
    let format = vImage_CGImageFormat(
      bitsPerComponent: PixelLayout.bitsPerComponent,
      bitsPerPixel: PixelLayout.bitsPerComponent,
      colorSpace: colorSpace,
      bitmapInfo: .init()
    )
  else {
    return nil
  }

  var bytes = bytes
  let cgImage: CGImage? = bytes.withUnsafeMutableBytes { pixels in
    var diffBuffer = vImage_Buffer(
      data: pixels.baseAddress,
      height: vImagePixelCount(height),
      width: vImagePixelCount(width),
      rowBytes: width
    )

    do {
      var stretchedBuffer = try vImage_Buffer(
        width: width,
        height: height,
        bitsPerPixel: UInt32(PixelLayout.bitsPerComponent)
      )
      defer { stretchedBuffer.free() }

      let error = vImageContrastStretch_Planar8(
        &diffBuffer,
        &stretchedBuffer,
        vImage_Flags(kvImageNoFlags)
      )

      let buffer = error == kvImageNoError ? stretchedBuffer : diffBuffer
      return try buffer.createCGImage(format: format)
    } catch {
      return nil
    }
  }

  return cgImage
}
#endif
