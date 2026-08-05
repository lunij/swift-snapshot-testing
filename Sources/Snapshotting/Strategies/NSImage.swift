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
  ///   - scale: The pixels a point of the recording is made of. The snapshot is rasterized at this
  ///     scale on its way to being recorded, whatever resolution its producer handed over, so that a
  ///     reference is the strategy's to describe rather than the screen's that happened to render
  ///     it. It never applies to the reference, which is read at the pixels it was recorded with; a
  ///     reference that disagrees is reported as a size mismatch, in pixels, naming both.
  ///
  ///     Rasterizing redraws the image, which resolves more detail only where there is more to
  ///     resolve: an image that draws itself — a symbol, a PDF, a drawing handler — renders again at
  ///     this resolution, while one that has already been rasterized is resampled onto it.
  public static func image(
    precision: Float = 1,
    perceptualPrecision: Float = 1,
    scale: CGFloat = SnapshotScale.default
  ) -> SnapshotStrategy {
    .init(
      pathExtension: "png",
      serializer: .image,
      comparator: .image(precision: precision, perceptualPrecision: perceptualPrecision)
    ) { image in
      // Rasterized here, before the image is either serialized or compared, so that the recording
      // and the comparison cannot come to different conclusions about how many pixels it has. Its
      // size in points is left alone: that is what says the pixels are worth `scale` of them each.
      NSImage(cgImage: try rasterize(image, scale: scale), size: image.size)
    }
  }
}

private func convertToData(_ image: NSImage) throws -> Data {
  let cgImage = try pixels(of: image)
  let rep = NSBitmapImageRep(cgImage: cgImage)
  // Giving the representation the image's size in points records how many of its pixels go to a
  // point, which AppKit writes to the file as its resolution and reads back when the reference is
  // loaded again.
  rep.size = image.size
  guard let data = rep.representation(using: .png, properties: [:]) else {
    throw ImageConversionError.pngDataConversionFailed
  }
  return data
}

/// An image's pixels at a named scale.
///
/// `cgImage(forProposedRect:context:hints:)` rasterizes a representation that has no pixels of its
/// own — a drawing handler, an SF Symbol, a PDF — at the main display's backing scale factor, and an
/// image that has several representations answers for its resolution with whichever one AppKit
/// picks. Neither is the snapshot's business, so a scale is named rather than discovered.
private func rasterize(_ image: NSImage, scale: CGFloat) throws -> CGImage {
  try requireNonEmpty(image)

  let pixelsWide = SnapshotScale.pixelCount(image.size.width, at: scale)
  let pixelsHigh = SnapshotScale.pixelCount(image.size.height, at: scale)

  // Pixels that already number what the scale asks for are handed over untouched; redrawing them
  // would only resample them onto themselves.
  if image.hasPixels,
    let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
    cgImage.width == pixelsWide,
    cgImage.height == pixelsHigh
  {
    return cgImage
  }

  return try redraw(image, pixelsWide: pixelsWide, pixelsHigh: pixelsHigh)
}

/// The pixels an image already carries, for one that has been rasterized already: a reference read
/// back from disk, or a snapshot on its way there.
///
/// The scale it was rasterized at is not asked about, because it is not this side's to decide — a
/// reference is read at the pixels it was recorded with, and a mismatch against the snapshot is the
/// comparison's to report.
private func pixels(of image: NSImage) throws -> CGImage {
  try requireNonEmpty(image)

  if image.hasPixels, let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
    return cgImage
  }

  // Reached only by a value that did not come through the strategy, which rasterizes first: the
  // serializer and the comparator are public on their own. Drawing it at the strategy's own default
  // is at least a reading the display cannot move.
  return try redraw(image, scale: SnapshotScale.default)
}

/// Snapshotting an image with no extent is a mistake worth reporting rather than a picture worth
/// comparing.
private func requireNonEmpty(_ image: NSImage) throws {
  if image.size == .zero {
    throw ImageConversionError.zeroSize
  }
  if image.size.width == 0 {
    throw ImageConversionError.zeroWidth
  }
  if image.size.height == 0 {
    throw ImageConversionError.zeroHeight
  }
}

extension NSImage {
  /// Whether any of the image's representations carries pixels, as opposed to a recipe for drawing
  /// them at whatever size it is asked for.
  fileprivate var hasPixels: Bool {
    representations.contains { $0.pixelsWide > 0 && $0.pixelsHigh > 0 }
  }
}

private func redraw(_ image: NSImage, scale: CGFloat) throws -> CGImage {
  try redraw(
    image,
    pixelsWide: SnapshotScale.pixelCount(image.size.width, at: scale),
    pixelsHigh: SnapshotScale.pixelCount(image.size.height, at: scale)
  )
}

private func redraw(_ image: NSImage, pixelsWide: Int, pixelsHigh: Int) throws -> CGImage {
  guard
    pixelsWide > 0,
    pixelsHigh > 0,
    let context = PixelLayout.context(width: pixelsWide, height: pixelsHigh)
  else {
    throw ImageConversionError.cgImageConversionFailed
  }

  // Scaling the context, rather than handing AppKit a representation whose pixels outnumber its
  // points, is what makes the image draw itself at this resolution: a representation is only a
  // request, which AppKit is free to satisfy from a rendering it cached at another scale.
  context.scaleBy(
    x: CGFloat(pixelsWide) / image.size.width,
    y: CGFloat(pixelsHigh) / image.size.height
  )
  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
  image.draw(in: CGRect(origin: .zero, size: image.size))
  NSGraphicsContext.restoreGraphicsState()

  guard let cgImage = context.makeImage() else {
    throw ImageConversionError.cgImageConversionFailed
  }
  return cgImage
}

private func compare(
  _ old: NSImage,
  _ new: NSImage,
  precision: Float,
  perceptualPrecision: Float
) throws -> ImageComparisonResult {
  let oldCgImage = try pixels(of: old)
  let newCgImage = try pixels(of: new)
  guard oldCgImage.width == newCgImage.width, oldCgImage.height == newCgImage.height else {
    return .unequalSize(old: oldCgImage.size, new: newCgImage.size)
  }
  guard let oldBuffer = PixelBuffer(oldCgImage) else {
    return .cgContextDataConversionFailed
  }
  if let newBuffer = PixelBuffer(newCgImage), oldBuffer.bytes == newBuffer.bytes {
    return .isMatching
  }
  let data = try convertToData(new)
  guard
    let newerImage = NSImage(data: data),
    let newerBuffer = PixelBuffer(try pixels(of: newerImage)),
    newerBuffer.byteCount == oldBuffer.byteCount
  else {
    return .cgContextDataConversionFailed
  }
  if oldBuffer.bytes == newerBuffer.bytes {
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
    let byteCount = oldBuffer.byteCount
    let byteCountThreshold = Int((1 - precision) * Float(byteCount))
    var differentByteCount = 0
    // NB: We are purposely using a verbose 'while' loop instead of a 'for in' loop.  When the
    //     compiler doesn't have optimizations enabled, a `while` loop is
    //     significantly faster than a `for` loop for iterating through the elements of a memory
    //     buffer. Details can be found in [SR-6983](https://github.com/apple/swift/issues/49531)
    var index = 0
    while index < byteCount {
      defer { index += 1 }
      if oldBuffer.bytes[index] != newerBuffer.bytes[index] {
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

private func diffImage(_ old: NSImage, _ new: NSImage) -> NSImage? {
  normalizedComponentDiff(old, new)
    ?? blendModeDiff(old, new)
}

/// Where the two images differ, for images whose pixel dimensions do not line up. Every pixel of
/// the larger canvas that only one image covers is that image's own, so a size mismatch shows up as
/// the region one of them leaves behind.
private func blendModeDiff(_ old: NSImage, _ new: NSImage) -> NSImage? {
  guard
    let oldCgImage = try? pixels(of: old),
    let newCgImage = try? pixels(of: new)
  else {
    return nil
  }

  let pixelsWide = max(oldCgImage.width, newCgImage.width)
  let pixelsHigh = max(oldCgImage.height, newCgImage.height)
  guard let context = PixelLayout.context(width: pixelsWide, height: pixelsHigh) else {
    return nil
  }

  context.draw(newCgImage, in: CGRect(origin: .zero, size: newCgImage.size))
  context.setBlendMode(.difference)
  context.draw(oldCgImage, in: CGRect(origin: .zero, size: oldCgImage.size))

  guard let cgImage = context.makeImage() else { return nil }
  return NSImage(cgImage: cgImage, size: CGSize(width: pixelsWide, height: pixelsHigh))
}

private func normalizedComponentDiff(_ old: NSImage, _ new: NSImage) -> NSImage? {
  guard
    let oldCgImage = try? pixels(of: old),
    let newCgImage = try? pixels(of: new),
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
      bitsPerComponent: PixelLayout.bitsPerComponent,
      bitsPerPixel: PixelLayout.bitsPerComponent,
      colorSpace: outputColorSpace,
      bitmapInfo: .init()
    )
  else {
    return nil
  }

  guard let oldBuffer = PixelBuffer(oldCgImage), let newBuffer = PixelBuffer(newCgImage) else {
    return nil
  }

  let width = oldBuffer.width
  let height = oldBuffer.height
  let pixelCount = oldBuffer.pixelCount

  var diffBytes = [UInt8](repeating: 0, count: pixelCount)
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
        bitsPerPixel: UInt32(PixelLayout.bitsPerComponent)
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
