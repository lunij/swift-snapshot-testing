#if os(iOS) || os(tvOS)
import Accelerate.vImage
import UIKit

extension SnapshotSerializer where Value == UIImage {
  /// A PNG serializer for UIImage, decoding references at scale 1.
  public static var image: SnapshotSerializer { .image() }

  /// A PNG serializer for UIImage.
  ///
  /// - Parameter scale: The scale used to decode the reference image from disk. Defaults to `1`.
  public static func image(scale: CGFloat = 1) -> SnapshotSerializer {
    SnapshotSerializer(
      toData: convertToData,
      fromData: { data in
        guard let image = UIImage(data: data, scale: scale) else {
          throw ImageConversionError.imageDecodingFailed
        }
        return image
      }
    )
  }
}

extension SnapshotComparator where Value == UIImage {
  /// A pixel-diffing comparator for UIImage that requires a 100% match.
  public static var image: SnapshotComparator { .image() }

  /// A pixel-diffing comparator for UIImage.
  ///
  /// - Parameters:
  ///   - precision: The percentage of pixels that must match.
  ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a
  ///     match. 98-99% mimics
  ///     [the precision](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e) of the
  ///     human eye.
  public static func image(
    precision: Float = 1,
    perceptualPrecision: Float = 1
  ) -> SnapshotComparator {
    SnapshotComparator { old, new in
      try compare(old, new, precision: precision, perceptualPrecision: perceptualPrecision)
        .snapshotFailure {
          try self.artifacts(old, new, diffImage, convertToData)
        }
    }
  }
}

extension Snapshotting where Value == UIImage, Format == UIImage {
  /// A snapshot strategy for comparing images based on pixel equality.
  public static var image: Snapshotting {
    .image()
  }

  /// A snapshot strategy for comparing images based on pixel equality.
  ///
  /// - Parameters:
  ///   - precision: The percentage of pixels that must match.
  ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a
  ///     match. 98-99% mimics
  ///     [the precision](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e) of the
  ///     human eye.
  ///   - scale: The scale of the reference image stored on disk.
  public static func image(
    precision: Float = 1,
    perceptualPrecision: Float = 1,
    scale: CGFloat = 1
  ) -> Snapshotting {
    .init(
      pathExtension: "png",
      serializer: .image(scale: scale),
      comparator: .image(precision: precision, perceptualPrecision: perceptualPrecision)
    )
  }
}

// remap snapshot & reference to same colorspace
private let imageContextColorSpace = CGColorSpace(name: CGColorSpace.sRGB)
private let imageContextBitsPerComponent = 8
private let imageContextBytesPerPixel = 4

private func convertToData(_ image: UIImage) throws -> Data {
  if image.size == .zero {
    throw ImageConversionError.zeroSize
  }
  if image.size.width == 0 {
    throw ImageConversionError.zeroWidth
  }
  if image.size.height == 0 {
    throw ImageConversionError.zeroHeight
  }
  guard let data = image.pngData() else {
    throw ImageConversionError.pngDataConversionFailed
  }
  return data
}

private func compare(_ old: UIImage, _ new: UIImage, precision: Float, perceptualPrecision: Float) -> ImageComparisonResult {
  guard let oldCgImage = old.cgImage, let newCgImage = new.cgImage else {
    return .cgImageConversionFailed
  }
  guard oldCgImage.width == newCgImage.width, oldCgImage.height == newCgImage.height else {
    return .unequalSize(old: oldCgImage.size, new: newCgImage.size)
  }
  let pixelCount = oldCgImage.width * oldCgImage.height
  let byteCount = imageContextBytesPerPixel * pixelCount
  var oldBytes = [UInt8](repeating: 0, count: byteCount)
  guard let oldData = context(for: oldCgImage, data: &oldBytes)?.data else {
    return .cgContextDataConversionFailed
  }
  if let newContext = context(for: newCgImage), let newData = newContext.data {
    if memcmp(oldData, newData, byteCount) == 0 {
      return .isMatching
    }
  }
  var newerBytes = [UInt8](repeating: 0, count: byteCount)
  guard
    let pngData = new.pngData(),
    let newerCgImage = UIImage(data: pngData)?.cgImage,
    let newerData = context(for: newerCgImage, data: &newerBytes)?.data
  else {
    return .cgContextDataConversionFailed
  }
  if memcmp(oldData, newerData, byteCount) == 0 {
    return .isMatching
  }
  if precision >= 1, perceptualPrecision >= 1 {
    return .isNotMatching
  }
  if perceptualPrecision < 1 {
    return perceptuallyCompare(
      CIImage(cgImage: oldCgImage),
      CIImage(cgImage: newCgImage),
      pixelPrecision: precision,
      perceptualPrecision: perceptualPrecision
    )
  } else {
    let byteCountThreshold = Int((1 - precision) * Float(byteCount))
    var differentByteCount = 0
    // NB: We are purposely using a verbose 'while' loop instead of a 'for in' loop.  When the
    //     compiler doesn't have optimizations enabled, like in test targets, a `while` loop is
    //     significantly faster than a `for` loop for iterating through the elements of a memory
    //     buffer. Details can be found in [SR-6983](https://github.com/apple/swift/issues/49531)
    var index = 0
    while index < byteCount {
      defer { index += 1 }
      if oldBytes[index] != newerBytes[index] {
        differentByteCount += 1
      }
    }
    if differentByteCount > byteCountThreshold {
      let actualPrecision = 1 - Float(differentByteCount) / Float(byteCount)
      return .unmatchedPrecision(expected: precision, actual: actualPrecision)
    }
  }
  return .isMatching
}

private func context(for cgImage: CGImage, data: UnsafeMutableRawPointer? = nil) -> CGContext? {
  let bytesPerRow = cgImage.width * imageContextBytesPerPixel
  guard
    let colorSpace = imageContextColorSpace,
    let context = CGContext(
      data: data,
      width: cgImage.width,
      height: cgImage.height,
      bitsPerComponent: imageContextBitsPerComponent,
      bytesPerRow: bytesPerRow,
      space: colorSpace,
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )
  else { return nil }

  context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
  return context
}

private func diffImage(_ old: UIImage, _ new: UIImage) -> UIImage {
  normalizedComponentDiff(old, new)
    ?? blendModeDiff(old, new)
}

private func blendModeDiff(_ old: UIImage, _ new: UIImage) -> UIImage {
  let width = max(old.size.width, new.size.width)
  let height = max(old.size.height, new.size.height)
  let format = UIGraphicsImageRendererFormat()
  format.scale = max(old.scale, new.scale)
  format.opaque = true
  return UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format).image { _ in
    new.draw(at: .zero)
    old.draw(at: .zero, blendMode: .difference, alpha: 1)
  }
}

private func normalizedComponentDiff(_ old: UIImage, _ new: UIImage) -> UIImage? {
  guard let oldCgImage = old.cgImage,
    let newCgImage = new.cgImage,
    oldCgImage.width == newCgImage.width,
    oldCgImage.height == newCgImage.height,
    oldCgImage.width > 0,
    oldCgImage.height > 0
  else {
    return nil
  }

  guard let outputColorSpace = CGColorSpace(name: CGColorSpace.linearGray),
    let outputFormat = vImage_CGImageFormat(
      bitsPerComponent: imageContextBitsPerComponent,
      bitsPerPixel: imageContextBitsPerComponent,
      colorSpace: outputColorSpace,
      bitmapInfo: .init()
    )
  else {
    return nil
  }

  let width = oldCgImage.width
  let height = oldCgImage.height
  let pixelCount = width * height
  let scale = old.scale

  // Draw both images into contexts with an identical, known layout (RGBA8888,
  // tightly packed rows). Reading the source images' raw backing bytes instead
  // would depend on their pixel format and row padding, which ImageIO does not
  // guarantee.
  let byteCount = pixelCount * imageContextBytesPerPixel
  var oldBytes = [UInt8](repeating: 0, count: byteCount)
  var newBytes = [UInt8](repeating: 0, count: byteCount)
  guard context(for: oldCgImage, data: &oldBytes) != nil,
    context(for: newCgImage, data: &newBytes) != nil
  else {
    return nil
  }
  var diffBytes = [UInt8](repeating: 0, count: pixelCount)

  var index = 0
  while index < pixelCount {
    defer { index += 1 }
    let pixelOffset = index * imageContextBytesPerPixel

    let rOld = Int16(oldBytes[pixelOffset])
    let gOld = Int16(oldBytes[pixelOffset + 1])
    let bOld = Int16(oldBytes[pixelOffset + 2])
    let aOld = Int16(oldBytes[pixelOffset + 3])

    let rNew = Int16(newBytes[pixelOffset])
    let gNew = Int16(newBytes[pixelOffset + 1])
    let bNew = Int16(newBytes[pixelOffset + 2])
    let aNew = Int16(newBytes[pixelOffset + 3])

    let rDiff = abs(rOld - rNew)
    let gDiff = abs(gOld - gNew)
    let bDiff = abs(bOld - bNew)
    let aDiff = abs(aOld - aNew)

    let maxDiff = max(rDiff, gDiff, bDiff, aDiff)
    diffBytes[index] = UInt8(maxDiff)
  }

  let outputCgImage: CGImage? = diffBytes.withUnsafeMutableBytes { diffPtr in
    var diffBuffer = vImage_Buffer(
      data: diffPtr.baseAddress,
      height: vImagePixelCount(height),
      width: vImagePixelCount(width),
      rowBytes: width
    )

    do {
      var normalizedBuffer = try vImage_Buffer(
        width: width,
        height: height,
        bitsPerPixel: UInt32(imageContextBitsPerComponent)
      )
      defer { normalizedBuffer.free() }

      let error = vImageContrastStretch_Planar8(
        &diffBuffer,
        &normalizedBuffer,
        vImage_Flags(kvImageNoFlags)
      )

      let buffer = error == kvImageNoError ? normalizedBuffer : diffBuffer

      return try buffer.createCGImage(format: outputFormat)
    } catch {
      return nil
    }
  }

  guard let outputCgImage else { return nil }

  return UIImage(cgImage: outputCgImage, scale: scale, orientation: .up)
}
#endif
