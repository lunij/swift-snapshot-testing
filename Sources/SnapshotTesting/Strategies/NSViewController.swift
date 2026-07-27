#if os(macOS)
import AppKit
import Cocoa

extension SnapshotStrategy where Value == NSViewController, Format == NSImage {
  /// A snapshot strategy for comparing view controller views based on pixel equality.
  public static var image: SnapshotStrategy {
    .image()
  }

  /// A snapshot strategy for comparing view controller views based on pixel equality.
  ///
  /// - Parameters:
  ///   - precision: The percentage of pixels that must match.
  ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a
  ///     match. 98-99% mimics
  ///     [the precision](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e) of the
  ///     human eye.
  ///   - size: A view size override.
  public static func image(
    precision: Float = 1,
    perceptualPrecision: Float = 1,
    size: CGSize? = nil
  ) -> SnapshotStrategy {
    SnapshotStrategy<NSView, NSImage>.image(
      precision: precision,
      perceptualPrecision: perceptualPrecision,
      size: size
    ).asyncPullback { @MainActor (vc: NSViewController) async -> NSView in vc.view }
  }
}

extension SnapshotStrategy where Value == NSViewController, Format == String {
  /// A snapshot strategy for comparing view controller views based on a recursive description of
  /// their properties and hierarchies.
  public static var recursiveDescription: SnapshotStrategy {
    SnapshotStrategy<NSView, String>.recursiveDescription.asyncPullback {
      @MainActor (vc: NSViewController) async -> NSView in vc.view
    }
  }
}
#endif
