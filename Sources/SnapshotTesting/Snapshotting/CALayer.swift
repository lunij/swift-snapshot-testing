#if os(macOS)
  import AppKit
  import Cocoa
  import QuartzCore

  extension Snapshotting where Value == CALayer, Format == NSImage {
    /// A snapshot strategy for comparing layers based on pixel equality.
    ///
    /// ``` swift
    /// // Match reference perfectly.
    /// assertSnapshot(of: layer, as: .image)
    ///
    /// // Allow for a 1% pixel difference.
    /// assertSnapshot(of: layer, as: .image(precision: 0.99))
    /// ```
    public static var image: Snapshotting {
      return .image(precision: 1)
    }

    /// A snapshot strategy for comparing layers based on pixel equality.
    ///
    /// - Parameters:
    ///   - precision: The percentage of pixels that must match.
    ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a
    ///     match. 98-99% mimics
    ///     [the precision](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e) of the
    ///     human eye.
    public static func image(precision: Float, perceptualPrecision: Float = 1) -> Snapshotting {
      return SimplySnapshotting.image(
        precision: precision, perceptualPrecision: perceptualPrecision
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
#elseif os(iOS) || os(tvOS)
  import UIKit

  extension Snapshotting where Value == CALayer, Format == UIImage {
    /// A snapshot strategy for comparing layers based on pixel equality.
    ///
    /// Every pixel must match the reference within a 99% perceptual tolerance, so imperceptible
    /// rendering differences (e.g. antialiasing) are allowed while any visible change fails.
    public static var image: Snapshotting {
      return .image()
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
      precision: Float = 1, perceptualPrecision: Float = 0.99, scale: CGFloat = 1, traits: @escaping TraitMutations = { _ in }
    )
      -> Snapshotting
    {
      return SimplySnapshotting.image(
        precision: precision, perceptualPrecision: perceptualPrecision, scale: scale
      ).pullback { layer in
        renderer(bounds: layer.bounds, scale: scale, traits: traits).image { ctx in
          layer.setNeedsLayout()
          layer.layoutIfNeeded()
          layer.render(in: ctx.cgContext)
        }
      }
    }
  }
#endif
