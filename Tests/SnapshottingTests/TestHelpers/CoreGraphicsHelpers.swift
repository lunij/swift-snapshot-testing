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

extension CGPath {
  /// Creates an approximation of a heart at a 45º angle with a circle above, using all available element types:
  static var heart: CGPath {
    let scale: CGFloat = 30.0
    let path = CGMutablePath()

    path.move(to: CGPoint(x: 0.0 * scale, y: 0.0 * scale))
    path.addLine(to: CGPoint(x: 0.0 * scale, y: 2.0 * scale))
    path.addQuadCurve(
      to: CGPoint(x: 1.0 * scale, y: 3.0 * scale),
      control: CGPoint(x: 0.125 * scale, y: 2.875 * scale)
    )
    path.addQuadCurve(
      to: CGPoint(x: 2.0 * scale, y: 2.0 * scale),
      control: CGPoint(x: 1.875 * scale, y: 2.875 * scale)
    )
    path.addCurve(
      to: CGPoint(x: 3.0 * scale, y: 1.0 * scale),
      control1: CGPoint(x: 2.5 * scale, y: 2.0 * scale),
      control2: CGPoint(x: 3.0 * scale, y: 1.5 * scale)
    )
    path.addCurve(
      to: CGPoint(x: 2.0 * scale, y: 0.0 * scale),
      control1: CGPoint(x: 3.0 * scale, y: 0.5 * scale),
      control2: CGPoint(x: 2.5 * scale, y: 0.0 * scale)
    )
    path.addLine(to: CGPoint(x: 0.0 * scale, y: 0.0 * scale))
    path.closeSubpath()

    path.addEllipse(
      in: CGRect(
        origin: CGPoint(x: 2.0 * scale, y: 2.0 * scale),
        size: CGSize(width: scale, height: scale)
      )
    )

    return path
  }
}
#endif

#if os(iOS) || os(tvOS)
import UIKit

extension UIBezierPath {
  /// Creates an approximation of a heart at a 45º angle with a circle above, using all available element types:
  static var heart: UIBezierPath {
    UIBezierPath(cgPath: .heart)
  }
}
#endif

#if os(macOS)
import AppKit

extension NSBezierPath {
  /// Creates an approximation of a heart at a 45º angle with a circle above, using all available element types:
  static var heart: NSBezierPath {
    let scale: CGFloat = 30.0
    let path = NSBezierPath()

    path.move(to: CGPoint(x: 0.0 * scale, y: 0.0 * scale))
    path.line(to: CGPoint(x: 0.0 * scale, y: 2.0 * scale))
    path.curve(
      to: CGPoint(x: 1.0 * scale, y: 3.0 * scale),
      controlPoint1: CGPoint(x: 0.0 * scale, y: 2.5 * scale),
      controlPoint2: CGPoint(x: 0.5 * scale, y: 3.0 * scale)
    )
    path.curve(
      to: CGPoint(x: 2.0 * scale, y: 2.0 * scale),
      controlPoint1: CGPoint(x: 1.5 * scale, y: 3.0 * scale),
      controlPoint2: CGPoint(x: 2.0 * scale, y: 2.5 * scale)
    )
    path.curve(
      to: CGPoint(x: 3.0 * scale, y: 1.0 * scale),
      controlPoint1: CGPoint(x: 2.5 * scale, y: 2.0 * scale),
      controlPoint2: CGPoint(x: 3.0 * scale, y: 1.5 * scale)
    )
    path.curve(
      to: CGPoint(x: 2.0 * scale, y: 0.0 * scale),
      controlPoint1: CGPoint(x: 3.0 * scale, y: 0.5 * scale),
      controlPoint2: CGPoint(x: 2.5 * scale, y: 0.0 * scale)
    )
    path.line(to: CGPoint(x: 0.0 * scale, y: 0.0 * scale))
    path.close()

    path.appendOval(
      in: CGRect(
        origin: CGPoint(x: 2.0 * scale, y: 2.0 * scale),
        size: CGSize(width: scale, height: scale)
      )
    )

    return path
  }
}
#endif
