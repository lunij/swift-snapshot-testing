#if os(iOS) || os(tvOS)
import UIKit

extension Snapshotting where Value == UIView, Format == UIImage {
  /// A snapshot strategy for comparing views based on pixel equality.
  ///
  /// Every pixel must match the reference within a 99% perceptual tolerance, so imperceptible
  /// rendering differences (e.g. antialiasing) are allowed while any visible change fails.
  public static var image: Snapshotting {
    return .image()
  }

  /// A snapshot strategy for comparing views based on pixel equality.
  ///
  /// - Parameters:
  ///   - drawHierarchyInKeyWindow: Utilize the simulator's key window in order to render
  ///     `UIAppearance` and `UIVisualEffect`s. This option requires a host application for your
  ///     tests and will _not_ work for framework test targets.
  ///   - precision: The percentage of pixels that must match. Defaults to `1`, requiring every
  ///     pixel to match within `perceptualPrecision`.
  ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a
  ///     match. 98-99% mimics
  ///     [the precision](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e) of the
  ///     human eye. Defaults to `0.99`, tolerating imperceptible rendering differences.
  ///   - scale: The scale at which the view is rendered and the reference image is stored.
  ///     Defaults to `2`.
  ///   - size: A view size override.
  ///   - traits: Trait overrides to apply when rendering.
  public static func image(
    drawHierarchyInKeyWindow: Bool = false,
    precision: Float = 1,
    perceptualPrecision: Float = 0.99,
    scale: CGFloat = 2,
    size: CGSize? = nil,
    traits: @escaping TraitMutations = { _ in }
  )
    -> Snapshotting
  {

    return SimplySnapshotting.image(
      precision: precision,
      perceptualPrecision: perceptualPrecision,
      scale: scale
    ).asyncPullback { view in
      snapshotView(
        config: .init(
          safeArea: .zero,
          scale: scale,
          size: size ?? view.frame.size
        ),
        drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
        traits: traits,
        view: view,
        viewController: .init()
      )
    }
  }
}

extension Snapshotting where Value == UIView, Format == String {
  /// A snapshot strategy for comparing views based on a recursive description of their properties
  /// and hierarchies.
  ///
  /// ``` swift
  /// s// Layout on the current device.
  /// assertSnapshot(of: view, as: .recursiveDescription)
  ///
  /// // Layout with a certain size.
  /// assertSnapshot(of: view, as: .recursiveDescription(size: .init(width: 22, height: 22)))
  ///
  /// // Layout with a certain trait collection.
  /// assertSnapshot(of: view, as: .recursiveDescription(traits: { $0.horizontalSizeClass = .regular }))
  /// ```
  ///
  /// Records:
  ///
  /// ```
  /// <UIButton; frame = (0 0; 22 22); opaque = NO; layer = <CALayer>>
  ///    | <UIImageView; frame = (0 0; 22 22); clipsToBounds = YES; opaque = NO; userInteractionEnabled = NO; layer = <CALayer>>
  /// ```
  public static var recursiveDescription: Snapshotting {
    return Snapshotting.recursiveDescription()
  }

  /// A snapshot strategy for comparing views based on a recursive description of their properties
  /// and hierarchies.
  public static func recursiveDescription(
    size: CGSize? = nil,
    traits: @escaping TraitMutations = { _ in }
  )
    -> Snapshotting<UIView, String>
  {
    return SimplySnapshotting.lines.pullback { view in
      let dispose = prepareView(
        config: .init(safeArea: .zero, size: size ?? view.frame.size, traits: traits),
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
