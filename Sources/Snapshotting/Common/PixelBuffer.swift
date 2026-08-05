#if os(iOS) || os(macOS) || os(tvOS)
import CoreGraphics

/// The bitmap layout every image comparison here reads pixels in: sRGB, eight bits a component, four
/// components a pixel, and rows packed tight.
///
/// A `CGImage` carries whatever layout its producer chose, and nothing promises which one that is:
/// ImageIO decodes a grayscale PNG to a single component a pixel, and pads each row out to a width it
/// finds convenient. Redrawing an image into one named layout, rather than reading the bytes it
/// happens to be backed by, is what lets a snapshot and a reference be subtracted from each other
/// byte by byte whatever each of them arrived as.
enum PixelLayout {
  static let bitsPerComponent = 8
  static let bytesPerPixel = 4
  static let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
  static let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

  /// The bytes a row of pixels occupies, there being no padding at the end of one.
  static func bytesPerRow(width: Int) -> Int {
    width * bytesPerPixel
  }

  /// A bitmap context of this layout.
  ///
  /// - Parameters:
  ///   - width: The context's width in pixels.
  ///   - height: The context's height in pixels.
  ///   - data: Memory to draw into, which has to outlive the context, or `nil` to let Core Graphics
  ///     allocate memory of its own.
  static func context(width: Int, height: Int, data: UnsafeMutableRawPointer? = nil) -> CGContext? {
    guard let colorSpace else { return nil }
    return CGContext(
      data: data,
      width: width,
      height: height,
      bitsPerComponent: bitsPerComponent,
      bytesPerRow: bytesPerRow(width: width),
      space: colorSpace,
      bitmapInfo: bitmapInfo
    )
  }
}

/// An image's pixels, in `PixelLayout`.
struct PixelBuffer {
  /// The width the image was drawn at, in pixels.
  let width: Int

  /// The height the image was drawn at, in pixels.
  let height: Int

  /// The pixels, row by row from the top, four bytes to each: red, green, blue, then alpha.
  let bytes: [UInt8]

  /// Draws an image into `PixelLayout` and keeps the bytes.
  ///
  /// Returns `nil` when Core Graphics will not draw the image at its own dimensions, which an image
  /// with no extent is the reachable case of.
  init?(_ cgImage: CGImage) {
    let width = cgImage.width
    let height = cgImage.height
    var bytes = [UInt8](repeating: 0, count: width * height * PixelLayout.bytesPerPixel)
    let drawn = bytes.withUnsafeMutableBytes { pixels -> Bool in
      guard
        let context = PixelLayout.context(width: width, height: height, data: pixels.baseAddress)
      else {
        return false
      }
      context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
      return true
    }
    guard drawn else { return nil }
    self.width = width
    self.height = height
    self.bytes = bytes
  }

  /// The pixels the buffer covers.
  var pixelCount: Int {
    width * height
  }

  /// The bytes the buffer is made of.
  var byteCount: Int {
    bytes.count
  }
}
#endif
