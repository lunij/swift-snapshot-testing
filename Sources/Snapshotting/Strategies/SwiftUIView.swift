#if canImport(SwiftUI)
import Foundation
@preconcurrency import SwiftUI
#if os(macOS)
@preconcurrency import AppKit
#endif

/// The size constraint for a snapshot (similar to `PreviewLayout`).
public enum SwiftUISnapshotLayout: Sendable {
  #if os(iOS) || os(tvOS)
  /// Center the view in a device container described by `profile`.
  case device(profile: DeviceProfile)
  #endif
  /// Center the view in a fixed size container.
  case fixed(width: CGFloat, height: CGFloat)
  /// Fit the view to the ideal size that fits its content.
  case sizeThatFits
}

#if os(iOS) || os(tvOS)
@available(iOS 13.0, tvOS 13.0, *)
extension SnapshotStrategy where Value: SwiftUI.View, Format == UIImage {

  /// A snapshot strategy for comparing SwiftUI Views based on pixel equality.
  ///
  /// Every pixel must match the reference within a 99% perceptual tolerance, so imperceptible
  /// rendering differences (e.g. antialiasing) are allowed while any visible change fails.
  public static var image: SnapshotStrategy {
    .image()
  }

  /// A snapshot strategy for comparing SwiftUI Views based on pixel equality.
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
  ///   - layout: A view layout override.
  ///   - scale: The scale at which the view is rendered and the reference image is stored.
  ///     Defaults to two on iPhone and iPad, and to one on Apple TV, whose screen is already large
  ///     enough in points that scaling it up costs more than it resolves.
  ///   - traits: Trait overrides to apply when rendering.
  public static func image(
    drawHierarchyInKeyWindow: Bool = false,
    precision: Float = 1,
    perceptualPrecision: Float = 0.99,
    layout: SwiftUISnapshotLayout = .sizeThatFits,
    scale: CGFloat = SnapshotScale.default,
    traits: @escaping TraitMutations = { _ in }
  )
    -> SnapshotStrategy
  {
    let profile: DeviceProfile

    switch layout {
    #if os(iOS) || os(tvOS)
    case let .device(profile: deviceProfile):
      profile = deviceProfile
    #endif
    case .sizeThatFits:
      profile = .init(safeArea: .zero, size: nil, traits: traits)
    case let .fixed(width: width, height: height):
      let size = CGSize(width: width, height: height)
      profile = .init(safeArea: .zero, size: size, traits: traits)
    }

    return DirectSnapshotStrategy.image(
      precision: precision,
      perceptualPrecision: perceptualPrecision,
      scale: scale
    ).transform { @MainActor view async throws in
      var profile = profile
      let controller: UIViewController

      if profile.size != nil {
        controller = UIHostingController(rootView: view)
      } else {
        let hostingController = UIHostingController(rootView: view)
        let maxSize = CGSize(width: 0.0, height: 0.0)
        profile.size = hostingController.sizeThatFits(in: maxSize)
        controller = hostingController
      }

      return try await snapshotView(
        profile: profile,
        in: drawHierarchyInKeyWindow ? .keyWindow : .offscreenWindow,
        scale: scale,
        traits: traits,
        view: controller.view,
        viewController: controller
      )
    }
  }
}
#endif

#if os(macOS)
@available(macOS 10.15, *)
extension SnapshotStrategy where Value: View, Format == NSImage {

  /// A snapshot strategy for comparing SwiftUI Views based on pixel equality.
  ///
  /// Every pixel must match the reference within a 99% perceptual tolerance, so imperceptible
  /// rendering differences (e.g. antialiasing) are allowed while any visible change fails.
  public static var image: SnapshotStrategy { .image() }

  /// A snapshot strategy for comparing SwiftUI Views based on pixel equality.
  ///
  /// - Parameters:
  ///   - precision: The percentage of pixels that must match. Defaults to `1`, requiring every
  ///     pixel to match within `perceptualPrecision`.
  ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a match.
  ///     98-99% mimics [the precision](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e) of the human eye.
  ///     Defaults to `0.99`, tolerating imperceptible rendering differences.
  ///   - layout: A view layout override.
  ///   - scale: The scale at which the view is rendered. Defaults to one, a Mac screen being large
  ///     enough in points not to need scaling past it.
  public static func image(
    precision: Float = 1,
    perceptualPrecision: Float = 0.99,
    layout: SwiftUISnapshotLayout = .sizeThatFits,
    scale: CGFloat = SnapshotScale.default
  ) -> SnapshotStrategy {
    DirectSnapshotStrategy
      .image(precision: precision, perceptualPrecision: perceptualPrecision, scale: scale)
      .transform { @MainActor view async in
        let controller = NSHostingController(rootView: view)
        let initialFrame = controller.view.frame

        let size: CGSize
        switch layout {
        case let .fixed(width, height):
          size = CGSize(width: width, height: height)
        case .sizeThatFits:
          size = controller.sizeThatFits(in: .zero)
        }

        let nsView = controller.view
        nsView.frame.size = size

        let views = await addImagesForRenderedViews(nsView)
        let image = nsView.convertToImage(scale: scale)
        for view in views { view.removeFromSuperview() }
        nsView.frame = initialFrame
        return image
      }
  }
}
#endif
#endif
