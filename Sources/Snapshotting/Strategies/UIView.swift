#if os(iOS) || os(tvOS)
import UIKit

extension SnapshotStrategy where Value == UIView, Format == UIImage {
  /// A snapshot strategy for comparing views based on pixel equality.
  ///
  /// Every pixel must match the reference within a 99% perceptual tolerance, so imperceptible
  /// rendering differences (e.g. antialiasing) are allowed while any visible change fails.
  public static var image: SnapshotStrategy {
    .image()
  }

  /// A snapshot strategy for comparing views based on pixel equality.
  ///
  /// - Parameters:
  ///   - drawHierarchyInKeyWindow: Utilize the simulator's key window in order to render
  ///     `UIAppearance` and `UIVisualEffect`s. This option requires a host
  ///     application and will _not_ work in a plain framework bundle.
  ///   - precision: The percentage of pixels that must match. Defaults to `1`, requiring every
  ///     pixel to match within `perceptualPrecision`.
  ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a
  ///     match. 98-99% mimics
  ///     [the precision](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e) of the
  ///     human eye. Defaults to `0.99`, tolerating imperceptible rendering differences.
  ///   - scale: The scale at which the view is rendered and the reference image is stored.
  ///     Defaults to two on iPhone and iPad, and to one on Apple TV, whose screen is already large
  ///     enough in points that scaling it up costs more than it resolves.
  ///   - size: A view size override.
  ///   - traits: Trait overrides to apply when rendering.
  public static func image(
    drawHierarchyInKeyWindow: Bool = false,
    precision: Float = 1,
    perceptualPrecision: Float = 0.99,
    scale: CGFloat = SnapshotScale.default,
    size: CGSize? = nil,
    traits: @escaping TraitMutations = { _ in }
  )
    -> SnapshotStrategy
  {
    DirectSnapshotStrategy.image(
      precision: precision,
      perceptualPrecision: perceptualPrecision,
      scale: scale
    ).transform { @MainActor view async in
      await snapshotView(
        profile: .init(safeArea: .zero, size: size ?? view.frame.size),
        drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
        scale: scale,
        traits: traits,
        view: view,
        viewController: .init()
      )
    }
  }
}

extension SnapshotStrategy where Value == UIView, Format == String {
  /// A snapshot strategy for comparing views based on a recursive description of their properties
  /// and hierarchies.
  ///
  /// The view is laid out on the current device by default; pass `size:` to lay it out at a
  /// certain size, or `traits:` to lay it out with a certain trait collection.
  ///
  /// Records:
  ///
  /// ```
  /// <UIButton; frame = (0 0; 22 22); opaque = NO; layer = <CALayer>>
  ///    | <UIImageView; frame = (0 0; 22 22); clipsToBounds = YES; opaque = NO; userInteractionEnabled = NO; layer = <CALayer>>
  /// ```
  public static var recursiveDescription: SnapshotStrategy {
    SnapshotStrategy.recursiveDescription()
  }

  /// A snapshot strategy for comparing views based on a recursive description of their properties
  /// and hierarchies.
  public static func recursiveDescription(
    size: CGSize? = nil,
    traits: @escaping TraitMutations = { _ in }
  )
    -> SnapshotStrategy<UIView, String>
  {
    DirectSnapshotStrategy.lines.transform(identifier: "recursive-description") { @MainActor view async in
      let dispose = prepareView(
        profile: .init(safeArea: .zero, size: size ?? view.frame.size, traits: traits),
        drawHierarchyInKeyWindow: false,
        traits: { _ in },
        view: view,
        viewController: .init()
      )
      defer { dispose() }
      return purgePointers(
        view.perform(Selector(("recursiveDescription"))).retain().takeUnretainedValue()
          as! String
      )
    }
  }
}
#endif
