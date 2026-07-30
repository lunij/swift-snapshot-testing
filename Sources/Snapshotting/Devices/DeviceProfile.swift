#if os(iOS) || os(tvOS)
import UIKit

/// The screen a view is laid out and rendered on.
///
/// A profile describes a device: the size of its screen in points, the insets its safe area
/// reserves, the scale it renders at, and the traits it reports — its idiom, its size classes, and
/// its input capabilities.
///
/// Profiles come from the device families — ``iPhone(_:_:)``, ``iPad(_:_:)``, ``tv`` and
/// ``tv4K`` — or from ``init(safeArea:scale:size:traits:)`` for a screen no device has.
public struct DeviceProfile: Sendable {
  /// The orientation a phone is held in.
  public enum Orientation: Sendable {
    case landscape
    case portrait
  }

  /// The orientation a tablet is held in, and the share of the screen the view occupies while
  /// another app is on screen beside it.
  public enum TabletOrientation: Sendable {
    public enum PortraitSplits: Sendable {
      case oneThird
      case twoThirds
      case full
    }
    public enum LandscapeSplits: Sendable {
      case oneThird
      case oneHalf
      case twoThirds
      case full
    }
    case landscape(splitView: LandscapeSplits)
    case portrait(splitView: PortraitSplits)

    /// Landscape, occupying the whole screen.
    public static var landscape: Self { .landscape(splitView: .full) }

    /// Portrait, occupying the whole screen.
    public static var portrait: Self { .portrait(splitView: .full) }
  }

  public var safeArea: UIEdgeInsets
  public var scale: CGFloat
  public var size: CGSize?
  public var traits: TraitMutations

  public init(
    safeArea: UIEdgeInsets = .zero,
    scale: CGFloat = 2,
    size: CGSize? = nil,
    traits: @escaping TraitMutations = { _ in }
  ) {
    self.safeArea = safeArea
    self.scale = scale
    self.size = size
    self.traits = traits
  }
}
#endif
