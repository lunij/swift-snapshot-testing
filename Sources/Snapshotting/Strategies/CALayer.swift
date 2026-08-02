#if canImport(AppKit)
import AppKit

extension SnapshotStrategy where Value == CALayer, Format == NSImage {
  /// A snapshot strategy for comparing layers based on pixel equality.
  ///
  /// Every pixel must match the reference. Use `image(precision:perceptualPrecision:)` to tolerate
  /// a percentage of differing pixels.
  public static var image: SnapshotStrategy { .image() }

  /// A snapshot strategy for comparing layers based on pixel equality.
  ///
  /// - Parameters:
  ///   - precision: The percentage of pixels that must match.
  ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a
  ///     match. 98-99% mimics
  ///     [the precision](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e) of the
  ///     human eye.
  public static func image(precision: Float = 1, perceptualPrecision: Float = 1) -> SnapshotStrategy {
    DirectSnapshotStrategy.image(
      precision: precision,
      perceptualPrecision: perceptualPrecision
    ).pullback { layer in
      let image = NSImage(size: layer.bounds.size)
      image.lockFocus()
      let context = NSGraphicsContext.current!.cgContext
      layer.setNeedsLayout()
      layer.layoutIfNeeded()
      layer.render(in: context)
      image.unlockFocus()
      return image
    }
  }
}
#elseif canImport(UIKit)
import UIKit

extension SnapshotStrategy where Value == CALayer, Format == UIImage {
  /// A snapshot strategy for comparing layers based on pixel equality.
  ///
  /// Every pixel must match the reference within a 99% perceptual tolerance, so imperceptible
  /// rendering differences (e.g. antialiasing) are allowed while any visible change fails.
  public static var image: SnapshotStrategy {
    .image()
  }

  /// A snapshot strategy for comparing layers based on pixel equality.
  ///
  /// - Parameters:
  ///   - precision: The percentage of pixels that must match. Defaults to `1`, requiring every
  ///     pixel to match within `perceptualPrecision`.
  ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a
  ///     match. 98-99% mimics
  ///     [the precision](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e) of the
  ///     human eye. Defaults to `0.99`, tolerating imperceptible rendering differences.
  ///   - scale: The scale at which the layer is rendered and the reference image is stored.
  ///     Defaults to `1`.
  ///   - traits: Trait overrides to apply when rendering.
  public static func image(
    precision: Float = 1,
    perceptualPrecision: Float = 0.99,
    scale: CGFloat = 1,
    traits: @escaping TraitMutations = { _ in }
  )
    -> SnapshotStrategy
  {
    DirectSnapshotStrategy.image(
      precision: precision,
      perceptualPrecision: perceptualPrecision,
      scale: scale
    ).asyncPullback { @MainActor (layer: CALayer) async -> UIImage in
      renderer(bounds: layer.bounds, scale: scale, traits: traits).image { ctx in
        layer.setNeedsLayout()
        layer.layoutIfNeeded()
        layer.render(in: ctx.cgContext)
      }
    }
  }
}
#endif
