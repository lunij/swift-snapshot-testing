#if os(macOS)
import Accelerate.vImage
import Cocoa

extension SnapshotSerializer where Value == NSImage {
  /// A PNG serializer for NSImage.
  public static var image: SnapshotSerializer {
    SnapshotSerializer(
      toData: convertToData,
      fromData: { data in
        guard let image = NSImage(data: data) else {
          throw ImageConversionError.imageDecodingFailed
        }
        return image
      }
    )
  }
}

extension SnapshotComparator where Value == NSImage {
  /// A pixel-diffing comparator for NSImage that requires a 100% match.
  public static var image: SnapshotComparator { .image() }

  /// A pixel-diffing comparator for NSImage.
  ///
  /// - Parameters:
  ///   - precision: The percentage of pixels that must match.
  ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a
  ///     match. 98-99% mimics
  ///     [the precision](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e) of the
  ///     human eye.
  public static func image(precision: Float = 1, perceptualPrecision: Float = 1) -> SnapshotComparator {
    SnapshotComparator { old, new in
      try compare(old, new, precision: precision, perceptualPrecision: perceptualPrecision)
        .snapshotFailure {
          try self.artifacts(old, new, diffImage, convertToData)
        }
    }
  }
}

extension SnapshotStrategy where Value == NSImage, Format == NSImage {
  /// A snapshot strategy for comparing images based on pixel equality.
  public static var image: SnapshotStrategy { .image() }

  /// A snapshot strategy for comparing images based on pixel equality.
  ///
  /// - Parameters:
  ///   - precision: The percentage of pixels that must match.
  ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a
  ///     match. 98-99% mimics
  ///     [the precision](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e) of the
  ///     human eye.
  public static func image(precision: Float = 1, perceptualPrecision: Float = 1) -> SnapshotStrategy {
    .init(
      pathExtension: "png",
      serializer: .image,
      comparator: .image(precision: precision, perceptualPrecision: perceptualPrecision)
    )
  }
}

// Remap snapshot & reference to the same colorspace and layout, matching the UIImage strategy.
private let imageContextColorSpace = CGColorSpace(name: CGColorSpace.sRGB)
private let imageContextBitsPerComponent = 8
private let imageContextBytesPerPixel = 4

private func convertToData(_ image: NSImage) throws -> Data {
  if image.size == .zero {
    throw ImageConversionError.zeroSize
  }
  if image.size.width == 0 {
    throw ImageConversionError.zeroWidth
  }
  if image.size.height == 0 {
    throw ImageConversionError.zeroHeight
  }
  guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    throw ImageConversionError.cgImageConversionFailed
  }
  let rep = NSBitmapImageRep(cgImage: cgImage)
  rep.size = image.size
  guard let data = rep.representation(using: .png, properties: [:]) else {
    throw ImageConversionError.pngDataConversionFailed
  }
  return data
}

private func compare(
  _ old: NSImage,
  _ new: NSImage,
  precision: Float,
  perceptualPrecision: Float
) -> ImageComparisonResult {
  guard let oldCgImage = old.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    return .cgImageConversionFailed
  }
  guard let newCgImage = new.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
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
    let data = try? convertToData(new),
    let newerCgImage = NSImage(data: data)?.cgImage(forProposedRect: nil, context: nil, hints: nil),
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
    //     compiler doesn't have optimizations enabled, a `while` loop is
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

private func diffImage(_ old: NSImage, _ new: NSImage) -> NSImage {
  normalizedComponentDiff(old, new)
    ?? blendModeDiff(old, new)
}

private func blendModeDiff(_ old: NSImage, _ new: NSImage) -> NSImage {
  let oldCiImage = CIImage(cgImage: old.cgImage(forProposedRect: nil, context: nil, hints: nil)!)
  let newCiImage = CIImage(cgImage: new.cgImage(forProposedRect: nil, context: nil, hints: nil)!)
  let differenceFilter = CIFilter(name: "CIDifferenceBlendMode")!
  differenceFilter.setValue(oldCiImage, forKey: kCIInputImageKey)
  differenceFilter.setValue(newCiImage, forKey: kCIInputBackgroundImageKey)
  let maxSize = CGSize(
    width: max(old.size.width, new.size.width),
    height: max(old.size.height, new.size.height)
  )
  let rep = NSCIImageRep(ciImage: differenceFilter.outputImage!)
  let difference = NSImage(size: maxSize)
  difference.addRepresentation(rep)
  return difference
}

private func normalizedComponentDiff(_ old: NSImage, _ new: NSImage) -> NSImage? {
  guard
    let oldCgImage = old.cgImage(forProposedRect: nil, context: nil, hints: nil),
    let newCgImage = new.cgImage(forProposedRect: nil, context: nil, hints: nil),
    oldCgImage.width == newCgImage.width,
    oldCgImage.height == newCgImage.height,
    oldCgImage.width > 0,
    oldCgImage.height > 0
  else {
    return nil
  }

  guard
    let outputColorSpace = CGColorSpace(name: CGColorSpace.linearGray),
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

  let byteCount = pixelCount * imageContextBytesPerPixel
  var oldBytes = [UInt8](repeating: 0, count: byteCount)
  var newBytes = [UInt8](repeating: 0, count: byteCount)
  guard
    context(for: oldCgImage, data: &oldBytes) != nil,
    context(for: newCgImage, data: &newBytes) != nil
  else {
    return nil
  }

  var diffBytes = [UInt8](repeating: 0, count: pixelCount)
  var index = 0
  while index < pixelCount {
    defer { index += 1 }
    let pixelOffset = index * imageContextBytesPerPixel
    let rDiff = abs(Int16(oldBytes[pixelOffset]) - Int16(newBytes[pixelOffset]))
    let gDiff = abs(Int16(oldBytes[pixelOffset + 1]) - Int16(newBytes[pixelOffset + 1]))
    let bDiff = abs(Int16(oldBytes[pixelOffset + 2]) - Int16(newBytes[pixelOffset + 2]))
    let aDiff = abs(Int16(oldBytes[pixelOffset + 3]) - Int16(newBytes[pixelOffset + 3]))
    diffBytes[index] = UInt8(max(rDiff, gDiff, bDiff, aDiff))
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
  return NSImage(cgImage: outputCgImage, size: old.size)
}
#endif
