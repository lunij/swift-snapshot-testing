#if os(macOS)
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
  try image.size.requireExtent()

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
  try image.size.requireExtent()

  if image.hasPixels, let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
    return cgImage
  }

  // Reached only by a value that did not come through the strategy, which rasterizes first: the
  // serializer and the comparator are public on their own. Drawing it at the strategy's own default
  // is at least a reading the display cannot move.
  return try redraw(image, scale: SnapshotScale.default)
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
  // Drawing into a canvas scaled to these pixels, rather than handing AppKit a representation whose
  // pixels outnumber its points, is what makes the image draw itself at this resolution: a
  // representation is only a request, which AppKit is free to satisfy from a rendering it cached at
  // another scale.
  let canvas = try BitmapCanvas(size: image.size, pixelsWide: pixelsWide, pixelsHigh: pixelsHigh)

  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = NSGraphicsContext(cgContext: canvas.context, flipped: false)
  image.draw(in: CGRect(origin: .zero, size: canvas.size))
  NSGraphicsContext.restoreGraphicsState()

  return try canvas.makeImage()
}

private func compare(
  _ old: NSImage,
  _ new: NSImage,
  precision: Float,
  perceptualPrecision: Float
) throws -> ImageComparisonResult {
  try comparePixels(
    pixels(of: old),
    pixels(of: new),
    precision: precision,
    perceptualPrecision: perceptualPrecision
  ) {
    guard let reencoded = NSImage(data: try convertToData(new)) else { return nil }
    return try pixels(of: reencoded)
  }
}

private func diffImage(_ old: NSImage, _ new: NSImage) -> NSImage? {
  guard
    let oldCgImage = try? pixels(of: old),
    let newCgImage = try? pixels(of: new),
    let diff = pixelDiff(oldCgImage, newCgImage)
  else {
    return nil
  }

  // A canvas in points that covers both images, matching the pixels the diff covers. The two only
  // disagree about their points when they disagree about their pixels, which is the mismatch the
  // diff is there to show.
  return NSImage(
    cgImage: diff,
    size: CGSize(
      width: max(old.size.width, new.size.width),
      height: max(old.size.height, new.size.height)
    )
  )
}
#endif
