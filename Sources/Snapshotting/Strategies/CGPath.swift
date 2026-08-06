#if os(macOS)
import Cocoa
import CoreGraphics

extension SnapshotStrategy where Value == CGPath, Format == NSImage {
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
  ///   - drawingMode: The drawing mode.
  public static func image(
    precision: Float = 1,
    perceptualPrecision: Float = 1,
    scale: CGFloat = 1,
    drawingMode: CGPathDrawingMode = .eoFill
  ) -> SnapshotStrategy {
    imageStrategy(
      precision: precision,
      perceptualPrecision: perceptualPrecision,
      scale: scale,
      drawingMode: drawingMode
    )
  }
}
#elseif os(iOS) || os(tvOS)
import CoreGraphics
import UIKit

extension SnapshotStrategy where Value == CGPath, Format == UIImage {
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
  ///   - drawingMode: The drawing mode.
  public static func image(
    precision: Float = 1,
    perceptualPrecision: Float = 1,
    scale: CGFloat = 1,
    drawingMode: CGPathDrawingMode = .eoFill
  ) -> SnapshotStrategy {
    imageStrategy(
      precision: precision,
      perceptualPrecision: perceptualPrecision,
      scale: scale,
      drawingMode: drawingMode
    )
  }
}
#endif

#if os(macOS) || os(iOS) || os(tvOS)
/// The strategy both platforms' `image` declare.
///
/// The two are spelled separately because a strategy names the format it records in, and the two
/// platforms do not share a public one. What they record is identical, so it is written once.
private func imageStrategy(
  precision: Float,
  perceptualPrecision: Float,
  scale: CGFloat,
  drawingMode: CGPathDrawingMode
) -> SnapshotStrategy<CGPath, XImage> {
  DirectSnapshotStrategy<XImage>.image(
    precision: precision,
    perceptualPrecision: perceptualPrecision,
    scale: scale
  ).transform { path in
    try path.convertToImage(drawingMode: drawingMode, scale: scale)
  }
}

extension SnapshotStrategy where Value == CGPath, Format == String {
  /// A snapshot strategy for comparing bezier paths based on element descriptions.
  public static var elementsDescription: SnapshotStrategy {
    .elementsDescription(numberFormatter: defaultNumberFormatter)
  }

  /// A snapshot strategy for comparing bezier paths based on element descriptions.
  ///
  /// - Parameter numberFormatter: The number formatter used for formatting points.
  public static func elementsDescription(numberFormatter: NumberFormatter) -> SnapshotStrategy {
    let namesByType: [CGPathElementType: String] = [
      .moveToPoint: "MoveTo",
      .addLineToPoint: "LineTo",
      .addQuadCurveToPoint: "QuadCurveTo",
      .addCurveToPoint: "CurveTo",
      .closeSubpath: "Close"
    ]

    let numberOfPointsByType: [CGPathElementType: Int] = [
      .moveToPoint: 1,
      .addLineToPoint: 1,
      .addQuadCurveToPoint: 2,
      .addCurveToPoint: 3,
      .closeSubpath: 0
    ]

    return DirectSnapshotStrategy.lines.transform(identifier: "elements-description") { path in
      var string: String = ""

      path.applyWithBlock { elementPointer in
        let element = elementPointer.pointee
        let name = namesByType[element.type] ?? "Unknown"

        if element.type == .moveToPoint && !string.isEmpty {
          string += "\n"
        }

        string += name

        if let numberOfPoints = numberOfPointsByType[element.type] {
          let points = UnsafeBufferPointer(start: element.points, count: numberOfPoints)
          string +=
            " "
            + points.map { point in
              let x = numberFormatter.string(from: point.x as NSNumber)!
              let y = numberFormatter.string(from: point.y as NSNumber)!
              return "(\(x), \(y))"
            }.joined(separator: " ")
        }

        string += "\n"
      }

      return string
    }
  }
}

private let defaultNumberFormatter: NumberFormatter = {
  let numberFormatter = NumberFormatter()
  numberFormatter.decimalSeparator = "."
  numberFormatter.minimumFractionDigits = 1
  numberFormatter.maximumFractionDigits = 3
  return numberFormatter
}()
#endif
