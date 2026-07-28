#if os(macOS)
import AppKit
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
  ///   - drawingMode: The drawing mode.
  public static func image(
    precision: Float = 1,
    perceptualPrecision: Float = 1,
    drawingMode: CGPathDrawingMode = .eoFill
  ) -> SnapshotStrategy {
    DirectSnapshotStrategy.image(
      precision: precision,
      perceptualPrecision: perceptualPrecision
    ).pullback { path in
      let bounds = path.boundingBoxOfPath
      var transform = CGAffineTransform(translationX: -bounds.origin.x, y: -bounds.origin.y)
      let path = path.copy(using: &transform)!

      // Draw into an explicitly sized bitmap so the image is rendered at 1x
      // regardless of the main display's backing scale factor.
      let bitmapRep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(ceil(bounds.width)),
        pixelsHigh: Int(ceil(bounds.height)),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .calibratedRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
      )!
      NSGraphicsContext.saveGraphicsState()
      defer { NSGraphicsContext.restoreGraphicsState() }
      let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmapRep)!
      NSGraphicsContext.current = graphicsContext

      let context = graphicsContext.cgContext
      context.addPath(path)
      context.drawPath(using: drawingMode)

      let image = NSImage(size: bounds.size)
      image.addRepresentation(bitmapRep)
      return image
    }
  }
}
#elseif os(iOS) || os(tvOS)
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
  public static func image(
    precision: Float = 1,
    perceptualPrecision: Float = 1,
    scale: CGFloat = 1,
    drawingMode: CGPathDrawingMode = .eoFill
  ) -> SnapshotStrategy {
    DirectSnapshotStrategy.image(
      precision: precision,
      perceptualPrecision: perceptualPrecision,
      scale: scale
    ).pullback { path in
      let bounds = path.boundingBoxOfPath
      let format = UIGraphicsImageRendererFormat.preferred()
      format.scale = scale
      return UIGraphicsImageRenderer(bounds: bounds, format: format).image { ctx in
        let cgContext = ctx.cgContext
        cgContext.addPath(path)
        cgContext.drawPath(using: drawingMode)
      }
    }
  }
}
#endif

#if os(macOS) || os(iOS) || os(tvOS)
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

    return DirectSnapshotStrategy.lines.pullback { path in
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
