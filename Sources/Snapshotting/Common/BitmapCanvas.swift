#if os(iOS) || os(macOS) || os(tvOS)
import CoreGraphics

/// A bitmap of `PixelLayout` with a size in points stretched over it: a fixed number of pixels that
/// whatever draws into them addresses in points, without being told how many pixels a point came to.
///
/// Sizing the bitmap in pixels, rather than asking a platform image to rasterize a size in points, is
/// what keeps a recording off the display it was made on — `NSImage.lockFocus` and
/// `NSBitmapImageRep` both rasterize at the main screen's backing scale factor whatever scale was
/// asked for.
struct BitmapCanvas {
  /// The size drawing into the canvas works in, in points.
  let size: CGSize

  /// The canvas's width in pixels.
  let pixelsWide: Int

  /// The canvas's height in pixels.
  let pixelsHigh: Int

  /// The context to draw into, scaled so that `size` covers every pixel of it.
  let context: CGContext

  /// A canvas covering a size in points at a scale.
  ///
  /// - Throws: ``ImageConversionError`` when the size has no extent, or when the pixels it comes to
  ///   cannot be allocated.
  init(size: CGSize, scale: CGFloat) throws {
    try self.init(
      size: size,
      pixelsWide: SnapshotScale.pixelCount(size.width, at: scale),
      pixelsHigh: SnapshotScale.pixelCount(size.height, at: scale)
    )
  }

  /// A canvas of a named number of pixels covering a size in points.
  ///
  /// - Throws: ``ImageConversionError`` when the size has no extent, or when the pixels cannot be
  ///   allocated.
  init(size: CGSize, pixelsWide: Int, pixelsHigh: Int) throws {
    try size.requireExtent()

    guard
      pixelsWide > 0,
      pixelsHigh > 0,
      let context = PixelLayout.context(width: pixelsWide, height: pixelsHigh)
    else {
      throw ImageConversionError.cgImageConversionFailed
    }

    // Taken from the pixel counts rather than from a scale so that the size covers the bitmap
    // exactly: a fractional size truncates to a whole number of pixels, and drawing at the scale
    // would leave the last row and column of it unpainted.
    context.scaleBy(x: CGFloat(pixelsWide) / size.width, y: CGFloat(pixelsHigh) / size.height)

    self.size = size
    self.pixelsWide = pixelsWide
    self.pixelsHigh = pixelsHigh
    self.context = context
  }

  /// The pixels drawn into the canvas so far.
  ///
  /// - Throws: ``ImageConversionError/cgImageConversionFailed`` when Core Graphics will not hand the
  ///   pixels over as an image.
  func makeImage() throws -> CGImage {
    guard let cgImage = context.makeImage() else {
      throw ImageConversionError.cgImageConversionFailed
    }
    return cgImage
  }
}
#endif
