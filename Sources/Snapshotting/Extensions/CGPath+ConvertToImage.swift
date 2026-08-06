#if os(macOS)
import Cocoa
#elseif os(iOS) || os(tvOS)
import UIKit
#endif

#if os(iOS) || os(macOS) || os(tvOS)
import CoreGraphics

/// The corner a path's coordinates are measured from.
///
/// Which one a path means is decided by whatever authored it, not by the machine the recording is
/// made on: a `CGPath` is written in Core Graphics' own space wherever it is drawn, while a
/// `UIBezierPath` is written in the coordinates its view lays out in. So a recording is the same
/// picture on every platform, and it is the same way up as the thing it depicts.
enum OriginCorner {
  /// Core Graphics' own, which AppKit shares: y grows upwards from the bottom left.
  case bottomLeft

  /// UIKit's: y grows downwards from the top left, UIKit handing drawing code a context flipped
  /// about its horizontal axis.
  case topLeft
}

extension CGPath {
  /// The path's own filling, at a named scale.
  ///
  /// The image covers the path's bounding box exactly: the path is moved onto the canvas rather than
  /// the canvas being grown to reach it, so a path drawn away from the origin records the same
  /// pixels as one drawn at it.
  ///
  /// - Parameters:
  ///   - drawingMode: How the path's interior is decided and painted.
  ///   - scale: The pixels a point of the recording is made of.
  ///   - origin: The corner the path measures its coordinates from.
  /// - Throws: ``ImageConversionError`` when the path encloses nothing, or when Core Graphics will
  ///   not hand its pixels over.
  func convertToImage(
    drawingMode: CGPathDrawingMode,
    scale: CGFloat,
    origin: OriginCorner
  ) throws -> XImage {
    let bounds = boundingBoxOfPath
    let canvas = try BitmapCanvas(size: bounds.size, scale: scale)
    let context = canvas.context

    if origin == .topLeft {
      context.translateBy(x: 0, y: bounds.height)
      context.scaleBy(x: 1, y: -1)
    }
    context.translateBy(x: -bounds.minX, y: -bounds.minY)

    context.addPath(self)
    context.drawPath(using: drawingMode)

    let cgImage = try canvas.makeImage()

    // The size in points is what says these pixels are worth `scale` of them each, so nothing is
    // resampled on the way to being recorded.
    #if os(macOS)
    return XImage(cgImage: cgImage, size: canvas.size)
    #else
    return XImage(cgImage: cgImage, scale: scale, orientation: .up)
    #endif
  }
}
#endif
