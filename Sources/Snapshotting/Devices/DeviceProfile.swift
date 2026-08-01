#if os(iOS) || os(tvOS)
import UIKit

/// The screen a view is laid out and rendered on.
///
/// A profile describes a device: the size of its screen in points, the insets its safe area
/// reserves, and the traits it reports — its idiom, its size classes, and its input capabilities.
/// It says nothing about resolution; the scale a snapshot rasterizes at is a parameter of the
/// image strategy, not a property of the device.
///
/// Profiles come from the device families — ``iPhone(_:_:)``, ``iPad(_:_:)`` and ``appleTV`` — or from
/// ``init(safeArea:size:traits:)`` for a screen no device has.
public struct DeviceProfile: Sendable {
  /// The orientation a device is held in.
  public enum Orientation: Sendable {
    case landscape
    case portrait
  }

  public var safeArea: UIEdgeInsets
  public var size: CGSize?
  public var traits: TraitMutations

  public init(
    safeArea: UIEdgeInsets = .zero,
    size: CGSize? = nil,
    traits: @escaping TraitMutations = { _ in }
  ) {
    self.safeArea = safeArea
    self.size = size
    self.traits = traits
  }

  /// The same screen, with the view in a window that spans only part of its width.
  ///
  /// A window reports a regular horizontal size class from ``regularWidth`` points across, and a
  /// compact one below it, whatever screen it sits on. The window keeps the height and the insets
  /// of the screen it came from.
  ///
  /// - Parameter width: The width of the window, in points.
  public func windowed(width: CGFloat) -> Self {
    var profile = self
    profile.size?.width = width
    let screenTraits = self.traits
    profile.traits = { traits in
      screenTraits(&traits)
      traits.horizontalSizeClass = width < Self.regularWidth ? .compact : .regular
    }
    return profile
  }

  /// The width, in points, from which a window is horizontally regular.
  public static let regularWidth: CGFloat = 640
}
#endif
