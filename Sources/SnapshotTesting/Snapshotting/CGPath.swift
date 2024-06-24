#if os(macOS)
  import AppKit
  import Cocoa
  import CoreGraphics

  extension Snapshotting where Value == CGPath, Format == NSImage {
    /// A snapshot strategy for comparing bezier paths based on pixel equality.
    public static var image: Snapshotting {
      return .image()
    }

    /// A snapshot strategy for comparing bezier paths based on pixel equality.
    ///
    /// ``` swift
    /// // Match reference perfectly.
    /// assertSnapshot(of: path, as: .image)
    ///
    /// // Allow for a 1% pixel difference.
    /// assertSnapshot(of: path, as: .image(precision: 0.99))
    /// ```
    ///
    /// - Parameters:
    ///   - precision: The percentage of pixels that must match.
    ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a
    ///     match. 98-99% mimics
    ///     [the precision](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e) of the
    ///     human eye.
    public static func image(
      precision: Float = 1, perceptualPrecision: Float = 1, drawingMode: CGPathDrawingMode = .eoFill
    ) -> Snapshotting {
      return SimplySnapshotting.image(
        precision: precision, perceptualPrecision: perceptualPrecision
      ).pullback { path in
        path.image(drawingMode: drawingMode) ?? NSImage()
      }
    }
  }

  private extension CGPath {
    func image(drawingMode: CGPathDrawingMode) -> NSImage? {
      guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
        return nil
      }

      let size = boundingBoxOfPath.size
      let context = CGContext(
        data: nil,
        width: Int(size.width),
        height: Int(size.height),
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      )

      guard let context else {
        return nil
      }

      context.addPath(self)
      context.drawPath(using: drawingMode)

      guard let cgImage = context.makeImage() else {
        return nil
      }

      return NSImage(cgImage: cgImage, size: size)
    }
  }
#elseif os(iOS) || os(tvOS) || os(visionOS)
  import UIKit

  extension Snapshotting where Value == CGPath, Format == UIImage {
    /// A snapshot strategy for comparing bezier paths based on pixel equality.
    public static var image: Snapshotting {
      return .image()
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
      precision: Float = 1, perceptualPrecision: Float = 1, scale: CGFloat = 1,
      drawingMode: CGPathDrawingMode = .eoFill
    ) -> Snapshotting {
      return SimplySnapshotting.image(
        precision: precision, perceptualPrecision: perceptualPrecision, scale: scale
      ).pullback { path in
        let bounds = path.boundingBoxOfPath
        let format: UIGraphicsImageRendererFormat
        if #available(iOS 11.0, tvOS 11.0, visionOS 1.0, *) {
          format = UIGraphicsImageRendererFormat.preferred()
        } else {
          format = UIGraphicsImageRendererFormat.default()
        }
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

#if os(macOS) || os(iOS) || os(tvOS) || os(visionOS)
  @available(iOS 11.0, OSX 10.13, tvOS 11.0, visionOS 1.0, *)
  extension Snapshotting where Value == CGPath, Format == String {
    /// A snapshot strategy for comparing bezier paths based on element descriptions.
    public static var elementsDescription: Snapshotting {
      .elementsDescription(numberFormatter: defaultNumberFormatter)
    }

    /// A snapshot strategy for comparing bezier paths based on element descriptions.
    ///
    /// - Parameter numberFormatter: The number formatter used for formatting points.
    public static func elementsDescription(numberFormatter: NumberFormatter) -> Snapshotting {
      let namesByType: [CGPathElementType: String] = [
        .moveToPoint: "MoveTo",
        .addLineToPoint: "LineTo",
        .addQuadCurveToPoint: "QuadCurveTo",
        .addCurveToPoint: "CurveTo",
        .closeSubpath: "Close",
      ]

      let numberOfPointsByType: [CGPathElementType: Int] = [
        .moveToPoint: 1,
        .addLineToPoint: 1,
        .addQuadCurveToPoint: 2,
        .addCurveToPoint: 3,
        .closeSubpath: 0,
      ]

      return SimplySnapshotting.lines.pullback { path in
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
    numberFormatter.minimumFractionDigits = 1
    numberFormatter.maximumFractionDigits = 3
    return numberFormatter
  }()
#endif
