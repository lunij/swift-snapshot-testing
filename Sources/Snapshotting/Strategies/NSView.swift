#if os(macOS)
import AppKit
import Cocoa

extension SnapshotStrategy where Value == NSView, Format == NSImage {
  /// A snapshot strategy for comparing views based on pixel equality.
  public static var image: SnapshotStrategy {
    .image()
  }

  /// A snapshot strategy for comparing views based on pixel equality.
  ///
  /// > Note: Snapshots must be compared on the same OS as the device that originally took the
  /// > reference to avoid discrepancies between images.
  ///
  /// - Parameters:
  ///   - precision: The percentage of pixels that must match.
  ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a
  ///     match. 98-99% mimics
  ///     [the precision](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e) of the
  ///     human eye.
  ///   - scale: A scale to use when rendering the view. Defaults to one, a Mac screen being large
  ///     enough in points not to need scaling past it.
  ///   - size: A view size override.
  public static func image(
    precision: Float = 1,
    perceptualPrecision: Float = 1,
    scale: CGFloat = SnapshotScale.default,
    size: CGSize? = nil
  ) -> SnapshotStrategy {
    DirectSnapshotStrategy.image(
      precision: precision,
      perceptualPrecision: perceptualPrecision,
      scale: scale
    ).transform { @MainActor view async in
      let initialSize = view.frame.size
      if let size = size { view.frame.size = size }
      if let snapshot = await view.snapshot {
        return snapshot
      }
      let views = await addImagesForRenderedViews(view)
      let image = view.convertToImage(scale: scale)
      for view in views { view.removeFromSuperview() }
      view.frame.size = initialSize
      return image
    }
  }
}

extension SnapshotStrategy where Value == NSView, Format == String {
  /// A snapshot strategy for comparing views based on a recursive description of their properties
  /// and hierarchies.
  ///
  /// Records:
  ///
  /// ```
  /// [   AF      LU ] h=--- v=--- NSButton "Push Me" f=(0,0,77,32) b=(-)
  ///   [   A       LU ] h=--- v=--- NSButtonBezelView f=(0,0,77,32) b=(-)
  ///   [   AF      LU ] h=--- v=--- NSButtonTextField "Push Me" f=(10,6,57,16) b=(-)
  /// ```
  public static var recursiveDescription: SnapshotStrategy<NSView, String> {
    DirectSnapshotStrategy.lines.transform(identifier: "recursive-description") { view in
      purgePointers(
        view.perform(Selector(("_subtreeDescription"))).retain().takeUnretainedValue()
          as! String
      )
    }
  }
}
#endif
