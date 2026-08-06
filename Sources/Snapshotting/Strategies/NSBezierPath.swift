#if os(macOS)
import AppKit
import Cocoa

extension SnapshotStrategy where Value == NSBezierPath, Format == NSImage {
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
      // The path's own winding rule, this being how it fills itself, and AppKit's corner, this
      // being the space it was laid out in.
      try path.cgPath.convertToImage(
        drawingMode: path.windingRule == .evenOdd ? .eoFill : .fill,
        scale: scale,
        origin: .bottomLeft
      )
    }
  }
}

extension SnapshotStrategy where Value == NSBezierPath, Format == String {
  /// A snapshot strategy for comparing bezier paths based on pixel equality.
  @available(macOS 11.0, *)
  @available(iOS 11.0, *)
  public static var elementsDescription: SnapshotStrategy {
    .elementsDescription(numberFormatter: defaultNumberFormatter)
  }

  /// A snapshot strategy for comparing bezier paths based on pixel equality.
  ///
  /// - Parameter numberFormatter: The number formatter used for formatting points.
  @available(macOS 11.0, *)
  @available(iOS 11.0, *)
  public static func elementsDescription(numberFormatter: NumberFormatter) -> SnapshotStrategy {
    let namesByType: [NSBezierPath.ElementType: String] = [
      .moveTo: "MoveTo",
      .lineTo: "LineTo",
      .quadraticCurveTo: "QuadCurveTo",
      .cubicCurveTo: "CubicCurveTo",
      .closePath: "Close"
    ]

    let numberOfPointsByType: [NSBezierPath.ElementType: Int] = [
      .moveTo: 1,
      .lineTo: 1,
      .quadraticCurveTo: 2,
      .cubicCurveTo: 3,
      .closePath: 0
    ]

    return DirectSnapshotStrategy.lines.transform(identifier: "elements-description") { path in
      var string: String = ""

      var elementPoints = [CGPoint](repeating: .zero, count: 3)
      for elementIndex in 0..<path.elementCount {
        let elementType = path.element(at: elementIndex, associatedPoints: &elementPoints)
        let name = namesByType[elementType] ?? "Unknown"

        if elementType == .moveTo && !string.isEmpty {
          string += "\n"
        }

        string += name

        if let numberOfPoints = numberOfPointsByType[elementType] {
          let points = elementPoints[0..<numberOfPoints]
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
