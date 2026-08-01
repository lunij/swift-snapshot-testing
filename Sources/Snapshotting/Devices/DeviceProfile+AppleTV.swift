#if os(tvOS)
import UIKit

extension DeviceProfile {
  /// 1920 × 1080 pt — the screen every Apple TV lays out on.
  ///
  /// One profile covers the whole family. tvOS reports the same geometry on an Apple TV HD, on an
  /// Apple TV 4K, and on a 4K set to output 1080p: the same 1920 × 1080 points, and the same insets
  /// reserved around them for overscan. What 4K changes is how many pixels that layout rasterizes
  /// to, which is the scale a snapshot renders at rather than anything the screen decides.
  public static let appleTV = DeviceProfile(
    safeArea: UIEdgeInsets(top: 60, left: 80, bottom: 60, right: 80),
    size: CGSize(width: 1920, height: 1080),
    traits: { traits in
      traits.horizontalSizeClass = .regular
      traits.verticalSizeClass = .regular
      traits.userInterfaceIdiom = .tv
    }
  )
}
#endif
