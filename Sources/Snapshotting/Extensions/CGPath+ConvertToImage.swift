#if os(macOS)
import Cocoa
#elseif os(iOS) || os(tvOS)
import UIKit
#endif

#if os(iOS) || os(macOS) || os(tvOS)
import CoreGraphics

/// Whether a point's y coordinate grows downwards, away from the origin at the top left corner.
///
/// A path is described in Core Graphics' own coordinate space, whose origin is at the bottom left,
/// but UIKit hands drawing code a context flipped about its horizontal axis and AppKit does not. A
/// recording made through either therefore depicts the same path either way up, so the convention is
/// the platform's to state rather than the path's.
private let originIsAtTopLeft: Bool = {
  #if canImport(UIKit)
  true
  #else
  false
  #endif
}()

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
  /// - Throws: ``ImageConversionError`` when the path encloses nothing, or when Core Graphics will
  ///   not hand its pixels over.
  func convertToImage(drawingMode: CGPathDrawingMode, scale: CGFloat) throws -> XImage {
    let bounds = boundingBoxOfPath
    let canvas = try BitmapCanvas(size: bounds.size, scale: scale)
    let context = canvas.context

    if originIsAtTopLeft {
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
