#if canImport(CoreGraphics)
import CoreGraphics

/// The scale a view rasterizes at, in pixels per point.
///
/// Scale is a property of a snapshot rather than of the screen it depicts. Layout happens entirely
/// in points, so rendering below a device's own scale produces a lower-resolution photograph of a
/// correct layout, not a wrong one. What it buys back is hairline width, `@2x` and `@3x` artwork,
/// and text rasterization — worth paying for on a phone, and not worth paying for on a television.
public enum SnapshotScale {
  /// The scale a view strategy renders at when the call site does not choose one.
  ///
  /// Two on iPhone and iPad, which resolves hairlines and picks `@2x` artwork while keeping a
  /// reference small enough to live in a repository.
  ///
  /// One on Apple TV and on the Mac, whose screens are large enough in points that scaling them up
  /// costs more than it resolves. An Apple TV lays out on 1920 × 1080 points, so at two it would
  /// rasterize 8.3 megapixels — paid for twice, once on disk and again in the perceptual comparison
  /// every assertion runs — to resolve detail on a screen nobody sits close to.
  public static var `default`: CGFloat {
    #if os(iOS)
    2
    #else
    1
    #endif
  }

  /// The pixels a length in points comes to at a scale.
  ///
  /// Truncating, not rounding, because that is what a renderer does with a fractional length: an
  /// `NSButton` 76.5 points across is drawn into 76 pixels at one. Anything deciding how many pixels
  /// a snapshot has must agree with whatever drew it, or a snapshot gets resampled onto a size it was
  /// never drawn at.
  static func pixelCount(_ points: CGFloat, at scale: CGFloat) -> Int {
    Int(points * scale)
  }
}
#endif
