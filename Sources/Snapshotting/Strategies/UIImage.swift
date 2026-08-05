#if os(iOS) || os(tvOS)
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

extension SnapshotStrategy where Value == UIImage, Format == UIImage {
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
  ///   - scale: The scale of the reference image stored on disk.
  public static func image(
    precision: Float = 1,
    perceptualPrecision: Float = 1,
    scale: CGFloat = 1
  ) -> SnapshotStrategy {
    .init(
      pathExtension: "png",
      serializer: .image(scale: scale),
      comparator: .image(precision: precision, perceptualPrecision: perceptualPrecision)
    )
  }
}

private func convertToData(_ image: UIImage) throws -> Data {
  try image.size.requireExtent()
  guard let data = image.pngData() else {
    throw ImageConversionError.pngDataConversionFailed
  }
  return data
}

private func compare(_ old: UIImage, _ new: UIImage, precision: Float, perceptualPrecision: Float) -> ImageComparisonResult {
  guard let oldCgImage = old.cgImage, let newCgImage = new.cgImage else {
    return .cgImageConversionFailed
  }
  return comparePixels(
    oldCgImage,
    newCgImage,
    precision: precision,
    perceptualPrecision: perceptualPrecision
  ) {
    guard let pngData = new.pngData() else { return nil }
    return UIImage(data: pngData)?.cgImage
  }
}

private func diffImage(_ old: UIImage, _ new: UIImage) -> UIImage {
  guard
    let oldCgImage = old.cgImage,
    let newCgImage = new.cgImage,
    let diff = normalizedComponentDiff(oldCgImage, newCgImage)
  else {
    return blendModeDiff(old, new)
  }
  return UIImage(cgImage: diff, scale: old.scale, orientation: .up)
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
#endif
