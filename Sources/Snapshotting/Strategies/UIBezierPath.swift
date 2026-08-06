#if os(iOS) || os(tvOS)
import UIKit

extension SnapshotStrategy where Value == UIBezierPath, Format == UIImage {
  /// A snapshot strategy for comparing bezier paths based on pixel equality.
  public static var image: SnapshotStrategy {
    .image()
  }

  /// A snapshot strategy for comparing bezier paths based on pixel equality.
  ///
  /// - Parameters:
  ///   - precision: The percentage of pixels that must match.
  ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a
  ///     match. 98-99% mimics
  ///     [the precision](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e) of the
  ///     human eye.
  ///   - scale: The pixels a point of the recording is made of.
  public static func image(
    precision: Float = 1,
    perceptualPrecision: Float = 1,
    scale: CGFloat = 1
  ) -> SnapshotStrategy {
    DirectSnapshotStrategy.image(
      precision: precision,
      perceptualPrecision: perceptualPrecision,
      scale: scale
    ).transform { path in
      // The path's own fill rule, this being how it fills itself.
      try path.cgPath.convertToImage(
        drawingMode: path.usesEvenOddFillRule ? .eoFill : .fill,
        scale: scale
      )
    }
  }
}

extension SnapshotStrategy where Value == UIBezierPath, Format == String {
  /// A snapshot strategy for comparing bezier paths based on pixel equality.
  public static var elementsDescription: SnapshotStrategy {
    SnapshotStrategy<CGPath, String>.elementsDescription.transform { $0.cgPath }
  }

  /// A snapshot strategy for comparing bezier paths based on pixel equality.
  ///
  /// - Parameter numberFormatter: The number formatter used for formatting points.
  public static func elementsDescription(numberFormatter: NumberFormatter) -> SnapshotStrategy {
    SnapshotStrategy<CGPath, String>.elementsDescription(
      numberFormatter: numberFormatter
    ).transform { $0.cgPath }
  }
}
#endif
