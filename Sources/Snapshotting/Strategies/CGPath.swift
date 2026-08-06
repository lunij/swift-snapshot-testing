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
    // A path is written in Core Graphics' coordinates whatever platform it is drawn on, so the
    // recording is the same picture everywhere and needs only the one reference.
    try path.convertToImage(drawingMode: drawingMode, scale: scale, origin: .bottomLeft)
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
      // `applyWithBlock` cannot carry a throw out of its closure, and the points it hands over are
      // only addressable for the length of the call, so every element is copied out before any of
      // them is described. A type of no known number of points keeps `nil` rather than an empty
      // array: an element that names none is written with the separator its points would have
      // followed, and one nothing is known about is written without it.
      var elements: [(type: CGPathElementType, points: [CGPoint]?)] = []

      path.applyWithBlock { elementPointer in
        let element = elementPointer.pointee
        elements.append(
          (
            type: element.type,
            points: numberOfPointsByType[element.type].map { numberOfPoints in
              Array(UnsafeBufferPointer(start: element.points, count: numberOfPoints))
            }
          )
        )
      }

      var string: String = ""

      for element in elements {
        if element.type == .moveToPoint && !string.isEmpty {
          string += "\n"
        }

        string += namesByType[element.type] ?? "Unknown"

        if let points = element.points {
          string += " " + (try points.map(numberFormatter.string(from:)).joined(separator: " "))
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
