#if os(iOS) || os(macOS) || os(tvOS)
import CoreGraphics

extension CGImage {
  /// A grayscale image, eight bits to a pixel, whose value at each point is `value(x, y)`.
  ///
  /// Grayscale is the point of it: an image built this way carries one component a pixel rather than
  /// four, and an odd width additionally pads each of its rows out, so it stands in for the layouts
  /// ImageIO hands back that indexing an image's own bytes as tightly-packed RGBA would misread.
  static func grayscale(
    width: Int,
    height: Int,
    value: (_ x: Int, _ y: Int) -> UInt8
  ) -> CGImage? {
    var bytes = [UInt8](repeating: 0, count: width * height)
    for y in 0..<height {
      for x in 0..<width {
        bytes[y * width + x] = value(x, y)
      }
    }
    return bytes.withUnsafeMutableBytes { pixels in
      guard
        let context = CGContext(
          data: pixels.baseAddress,
          width: width,
          height: height,
          bitsPerComponent: 8,
          bytesPerRow: width,
          space: CGColorSpaceCreateDeviceGray(),
          bitmapInfo: CGImageAlphaInfo.none.rawValue
        )
      else { return nil }
      return context.makeImage()
    }
  }
}

extension CGImage {
  /// An image of four bytes a pixel — red, green, blue, then alpha — whose pixel at each point is
  /// `value(x, y)`.
  ///
  /// Alpha is premultiplied, as an image handed around by Core Graphics is, so a pixel that is not
  /// opaque comes back with its color components scaled down: a test that means to move alpha on its
  /// own leaves them at zero.
  static func rgba(
    width: Int,
    height: Int,
    value: (_ x: Int, _ y: Int) -> (red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8)
  ) -> CGImage? {
    var bytes = [UInt8](repeating: 0, count: width * height * 4)
    for y in 0..<height {
      for x in 0..<width {
        let pixel = value(x, y)
        let offset = (y * width + x) * 4
        bytes[offset] = pixel.red
        bytes[offset + 1] = pixel.green
        bytes[offset + 2] = pixel.blue
        bytes[offset + 3] = pixel.alpha
      }
    }
    return bytes.withUnsafeMutableBytes { pixels in
      guard
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
        let context = CGContext(
          data: pixels.baseAddress,
          width: width,
          height: height,
          bitsPerComponent: 8,
          bytesPerRow: width * 4,
          space: colorSpace,
          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
      else { return nil }
      return context.makeImage()
    }
  }
}

extension CGPath {
  static var fixture: CGPath {
    let path = CGMutablePath()

    for corner in [CGPoint(x: 0, y: 0), CGPoint(x: 60, y: 60)] {
      let point = { (x: CGFloat, y: CGFloat) in CGPoint(x: corner.x + x, y: corner.y + y) }

      path.move(to: point(0, 0))
      path.addLine(to: point(60, 0))
      path.addQuadCurve(to: point(60, 60), control: point(40, 30))
      path.addCurve(to: point(0, 60), control1: point(40, 50), control2: point(20, 50))
      path.closeSubpath()
    }

    return path
  }
}
#endif

#if canImport(AppKit)
import AppKit

extension NSBezierPath {
  static var fixture: NSBezierPath {
    let path = NSBezierPath()

    for corner in [CGPoint(x: 0, y: 0), CGPoint(x: 60, y: 60)] {
      let point = { (x: CGFloat, y: CGFloat) in CGPoint(x: corner.x + x, y: corner.y + y) }

      path.move(to: point(0, 0))
      path.line(to: point(60, 0))
      path.curve(to: point(60, 60), controlPoint: point(40, 30))
      path.curve(to: point(0, 60), controlPoint1: point(40, 50), controlPoint2: point(20, 50))
      path.close()
    }

    return path
  }
}
#elseif canImport(UIKit)
import UIKit

extension UIBezierPath {
  static var fixture: UIBezierPath {
    UIBezierPath(cgPath: .fixture)
  }
}
#endif
