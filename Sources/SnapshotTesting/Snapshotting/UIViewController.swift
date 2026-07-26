#if os(iOS) || os(tvOS)
import UIKit

extension Snapshotting where Value == UIViewController, Format == UIImage {
  /// A snapshot strategy for comparing view controller views based on pixel equality.
  ///
  /// Every pixel must match the reference within a 99% perceptual tolerance, so imperceptible
  /// rendering differences (e.g. antialiasing) are allowed while any visible change fails.
  public static var image: Snapshotting {
    .image()
  }

  /// A snapshot strategy for comparing view controller views based on pixel equality.
  ///
  /// - Parameters:
  ///   - config: A set of device configuration settings.
  ///   - drawHierarchyInKeyWindow: Utilize the simulator's key window in order to render
  ///     `UIAppearance` and `UIVisualEffect`s. This option requires a host application for your
  ///     tests and will _not_ work for framework test targets.
  ///   - precision: The percentage of pixels that must match. Defaults to `1`, requiring every
  ///     pixel to match within `perceptualPrecision`.
  ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a
  ///     match. 98-99% mimics
  ///     [the precision](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e) of the
  ///     human eye. Defaults to `0.99`, tolerating imperceptible rendering differences.
  ///   - size: A view size override.
  ///   - traits: Trait overrides to apply when rendering.
  public static func image(
    on config: ViewImageConfig,
    drawHierarchyInKeyWindow: Bool = false,
    precision: Float = 1,
    perceptualPrecision: Float = 0.99,
    size: CGSize? = nil,
    traits: @escaping TraitMutations = { _ in }
  )
    -> Snapshotting
  {
    SimplySnapshotting.image(
      precision: precision,
      perceptualPrecision: perceptualPrecision,
      scale: config.scale
    ).asyncPullback { @MainActor (viewController: UIViewController) async -> UIImage in
      await snapshotView(
        config: size.map { .init(safeArea: config.safeArea, size: $0, traits: config.traits) }
          ?? config,
        drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
        traits: traits,
        view: viewController.view,
        viewController: viewController
      )
    }
  }

  /// A snapshot strategy for comparing view controller views based on pixel equality.
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
    SimplySnapshotting.image(
      precision: precision,
      perceptualPrecision: perceptualPrecision,
      scale: scale
    ).asyncPullback { @MainActor (viewController: UIViewController) async -> UIImage in
      await snapshotView(
        config: .init(safeArea: .zero, size: size, traits: traits),
        drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
        traits: traits,
        view: viewController.view,
        viewController: viewController
      )
    }
  }
}

extension Snapshotting where Value == UIViewController, Format == String {
  /// A snapshot strategy for comparing view controllers based on their embedded controller
  /// hierarchy.
  ///
  /// ``` swift
  /// assertSnapshot(of: vc, as: .hierarchy)
  /// ```
  ///
  /// Records:
  ///
  /// ```
  /// <UITabBarController>, state: appeared, view: <UILayoutContainerView>
  ///    | <UINavigationController>, state: appeared, view: <UILayoutContainerView>
  ///    |    | <UIPageViewController>, state: appeared, view: <_UIPageViewControllerContentView>
  ///    |    |    | <UIViewController>, state: appeared, view: <UIView>
  ///    | <UINavigationController>, state: disappeared, view: <UILayoutContainerView> not in the window
  ///    |    | <UIViewController>, state: disappeared, view: (view not loaded)
  ///    | <UINavigationController>, state: disappeared, view: <UILayoutContainerView> not in the window
  ///    |    | <UIViewController>, state: disappeared, view: (view not loaded)
  ///    | <UINavigationController>, state: disappeared, view: <UILayoutContainerView> not in the window
  ///    |    | <UIViewController>, state: disappeared, view: (view not loaded)
  ///    | <UINavigationController>, state: disappeared, view: <UILayoutContainerView> not in the window
  ///    |    | <UIViewController>, state: disappeared, view: (view not loaded)
  /// ```
  public static var hierarchy: Snapshotting {
    Snapshotting<String, String>.lines.asyncPullback { @MainActor (viewController: UIViewController) async -> String in
      let dispose = prepareView(
        config: .init(),
        drawHierarchyInKeyWindow: false,
        traits: { _ in },
        view: viewController.view,
        viewController: viewController
      )
      defer { dispose() }
      return purgePointers(
        viewController.perform(Selector(("_printHierarchy"))).retain().takeUnretainedValue()
          as! String
      )
    }
  }

  /// A snapshot strategy for comparing view controllers based on a recursive description of
  /// their properties and hierarchies.
  public static var recursiveDescription: Snapshotting {
    Snapshotting.recursiveDescription()
  }

  /// A snapshot strategy for comparing view controllers based on a recursive description of
  /// their properties and hierarchies.
  ///
  /// - Parameters:
  ///   - config: A set of device configuration settings.
  ///   - size: A view size override.
  ///   - traits: Trait overrides to apply when rendering.
  public static func recursiveDescription(
    on config: ViewImageConfig = .init(),
    size: CGSize? = nil,
    traits: @escaping TraitMutations = { _ in }
  )
    -> Snapshotting<UIViewController, String>
  {
    SimplySnapshotting.lines.asyncPullback { @MainActor (viewController: UIViewController) async -> String in
      let dispose = prepareView(
        config: .init(
          safeArea: config.safeArea,
          size: size ?? config.size,
          traits: config.traits
        ),
        drawHierarchyInKeyWindow: false,
        traits: traits,
        view: viewController.view,
        viewController: viewController
      )
      defer { dispose() }
      return purgePointers(
        viewController.view.perform(Selector(("recursiveDescription"))).retain()
          .takeUnretainedValue()
          as! String
      )
    }
  }
}
#endif
