#if os(iOS) || os(tvOS)
import UIKit

extension SnapshotStrategy where Value == UIViewController, Format == UIImage {
  /// A snapshot strategy for comparing view controller views based on pixel equality.
  ///
  /// Every pixel must match the reference within a 99% perceptual tolerance, so imperceptible
  /// rendering differences (e.g. antialiasing) are allowed while any visible change fails.
  public static var image: SnapshotStrategy {
    .image()
  }

  /// A snapshot strategy for comparing view controller views based on pixel equality.
  ///
  /// - Parameters:
  ///   - profile: The device the view controller's view is laid out and rendered on.
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
  ///     Defaults to `2`, which keeps references small enough to live in a repository while still
  ///     resolving hairlines. Pass the device's own scale for pixel fidelity.
  ///   - size: A view size override.
  ///   - traits: Trait overrides to apply when rendering.
  public static func image(
    on profile: DeviceProfile,
    drawHierarchyInKeyWindow: Bool = false,
    precision: Float = 1,
    perceptualPrecision: Float = 0.99,
    scale: CGFloat = 2,
    size: CGSize? = nil,
    traits: @escaping TraitMutations = { _ in }
  )
    -> SnapshotStrategy
  {
    DirectSnapshotStrategy.image(
      precision: precision,
      perceptualPrecision: perceptualPrecision,
      scale: scale
    ).asyncPullback { @MainActor (viewController: UIViewController) async -> UIImage in
      await snapshotView(
        profile: size.map { .init(safeArea: profile.safeArea, size: $0, traits: profile.traits) }
          ?? profile,
        drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
        scale: scale,
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
  ///     `UIAppearance` and `UIVisualEffect`s. This option requires a host
  ///     application and will _not_ work in a plain framework bundle.
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
    -> SnapshotStrategy
  {
    DirectSnapshotStrategy.image(
      precision: precision,
      perceptualPrecision: perceptualPrecision,
      scale: scale
    ).asyncPullback { @MainActor (viewController: UIViewController) async -> UIImage in
      await snapshotView(
        profile: .init(safeArea: .zero, size: size, traits: traits),
        drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
        scale: scale,
        traits: traits,
        view: viewController.view,
        viewController: viewController
      )
    }
  }
}

extension SnapshotStrategy where Value == UIViewController, Format == String {
  /// A snapshot strategy for comparing view controllers based on their embedded controller
  /// hierarchy.
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
  public static var hierarchy: SnapshotStrategy {
    SnapshotStrategy<String, String>.lines.asyncPullback { @MainActor (viewController: UIViewController) async -> String in
      let dispose = prepareView(
        profile: .init(),
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
  public static var recursiveDescription: SnapshotStrategy {
    SnapshotStrategy.recursiveDescription()
  }

  /// A snapshot strategy for comparing view controllers based on a recursive description of
  /// their properties and hierarchies.
  ///
  /// - Parameters:
  ///   - profile: The device the view controller's view is laid out on.
  ///   - size: A view size override.
  ///   - traits: Trait overrides to apply when rendering.
  public static func recursiveDescription(
    on profile: DeviceProfile = .init(),
    size: CGSize? = nil,
    traits: @escaping TraitMutations = { _ in }
  )
    -> SnapshotStrategy<UIViewController, String>
  {
    DirectSnapshotStrategy.lines.asyncPullback { @MainActor (viewController: UIViewController) async -> String in
      let dispose = prepareView(
        profile: .init(
          safeArea: profile.safeArea,
          size: size ?? profile.size,
          traits: profile.traits
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
