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
  ///   - scale: The pixels a point of the recording is made of. The layer draws itself at this
  ///     resolution, so a reference is the strategy's to describe rather than the display's that
  ///     happened to be attached.
  public static func image(
    precision: Float = 1,
    perceptualPrecision: Float = 1,
    scale: CGFloat = SnapshotScale.default
  ) -> SnapshotStrategy {
    DirectSnapshotStrategy.image(
      precision: precision,
      perceptualPrecision: perceptualPrecision,
      scale: scale
    ).transform { layer in
      try render(layer, scale: scale)
    }
  }
}

/// A layer's own rendering, at a named scale.
///
/// Drawing into a bitmap sized in pixels, rather than locking focus on an `NSImage`, is what keeps
/// the recording off the display: `lockFocus` rasterizes at the main screen's backing scale factor
/// whatever scale was asked for, which leaves a Retina machine recording a rendering that has to be
/// resampled down again and a machine attached to a single-density display recording one that does
/// not — different pixels for the same layer.
private func render(_ layer: CALayer, scale: CGFloat) throws -> NSImage {
  let size = layer.bounds.size
  if size == .zero {
    throw ImageConversionError.zeroSize
  }
  if size.width == 0 {
    throw ImageConversionError.zeroWidth
  }
  if size.height == 0 {
    throw ImageConversionError.zeroHeight
  }

  let pixelsWide = SnapshotScale.pixelCount(size.width, at: scale)
  let pixelsHigh = SnapshotScale.pixelCount(size.height, at: scale)

  guard
    pixelsWide > 0,
    pixelsHigh > 0,
    let colorSpace = imageContextColorSpace,
    let context = CGContext(
      data: nil,
      width: pixelsWide,
      height: pixelsHigh,
      bitsPerComponent: imageContextBitsPerComponent,
      bytesPerRow: pixelsWide * imageContextBytesPerPixel,
      space: colorSpace,
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )
  else {
    throw ImageConversionError.cgImageConversionFailed
  }

  // Taken from the pixel counts rather than from `scale` itself so that the layer covers the bitmap
  // exactly: a fractional bounds truncates to a whole number of pixels, and drawing at `scale` would
  // leave the last row and column of it unpainted.
  context.scaleBy(x: CGFloat(pixelsWide) / size.width, y: CGFloat(pixelsHigh) / size.height)

  layer.setNeedsLayout()
  layer.layoutIfNeeded()
  layer.render(in: context)

  guard let cgImage = context.makeImage() else {
    throw ImageConversionError.cgImageConversionFailed
  }

  // The size in points is what says these pixels are worth `scale` of them each, and it is what the
  // `NSImage` strategy measures its own rasterization against, so nothing is resampled on the way to
  // being recorded.
  return NSImage(cgImage: cgImage, size: size)
}

// Matches the context the NSImage strategy compares in, so the layer is drawn in the colorspace and
// layout its reference is read back in.
private let imageContextColorSpace = CGColorSpace(name: CGColorSpace.sRGB)
private let imageContextBitsPerComponent = 8
private let imageContextBytesPerPixel = 4
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
    ).transform { @MainActor layer async in
      renderer(bounds: layer.bounds, scale: scale, traits: traits).image { ctx in
        layer.setNeedsLayout()
        layer.layoutIfNeeded()
        layer.render(in: ctx.cgContext)
      }
    }
  }
}
#endif
