#if os(iOS) || os(macOS) || os(tvOS)
import CoreGraphics

extension CGSize {
  /// Checks that the size has an extent to draw.
  ///
  /// Snapshotting something with no extent is a mistake worth reporting rather than a picture worth
  /// comparing: it is a view that was never laid out, or one whose constraints came to nothing.
  ///
  /// - Throws: ``ImageConversionError/zeroSize``, ``ImageConversionError/zeroWidth`` or
  ///   ``ImageConversionError/zeroHeight``, in that order, so that an entirely empty size is named as
  ///   such rather than as one of its two dimensions.
  func requireExtent() throws {
    if self == .zero {
      throw ImageConversionError.zeroSize
    }
    if width == 0 {
      throw ImageConversionError.zeroWidth
    }
    if height == 0 {
      throw ImageConversionError.zeroHeight
    }
  }
}
#endif
