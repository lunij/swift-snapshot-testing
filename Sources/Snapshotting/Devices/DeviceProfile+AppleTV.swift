#if os(tvOS)
import UIKit

extension DeviceProfile {
  /// 1920 × 1080 pt — Apple TV HD.
  public static let tv = DeviceProfile(
    safeArea: UIEdgeInsets(top: 60, left: 90, bottom: 60, right: 90),
    size: CGSize(width: 1920, height: 1080)
  )

  /// 3840 × 2160 pt — Apple TV 4K.
  public static let tv4K = DeviceProfile(
    safeArea: UIEdgeInsets(top: 120, left: 180, bottom: 120, right: 180),
    size: CGSize(width: 3840, height: 2160)
  )
}
#endif
