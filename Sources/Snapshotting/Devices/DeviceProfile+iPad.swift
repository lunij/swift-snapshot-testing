#if os(iOS)
import UIKit

extension DeviceProfile {
  /// A family of iPads that share a screen.
  ///
  /// Cases are named for the year their screen first shipped.
  public enum TabletGeneration: Sendable {
    /// 1024 × 768 pt — iPad (1st–6th generation), iPad 9.7", iPad Air, Air 2, iPad mini (1st–5th generation).
    case year2010

    /// 1366 × 1024 pt — iPad Pro 12.9" (1st, 2nd generation).
    case year2015

    /// 1112 × 834 pt — iPad Pro 10.5", iPad Air (3rd generation).
    case year2017

    /// 1194 × 834 pt — iPad Pro 11" (1st–4th generation).
    case year2018

    /// 1080 × 810 pt — iPad (7th, 8th, 9th generation), iPad 10.2".
    case year2019
  }

  /// A profile for an iPad screen.
  ///
  /// Narrow the profile with ``windowed(width:)`` to lay the view out in a window that spans only
  /// part of the screen.
  ///
  /// - Parameters:
  ///   - generation: The family of iPads to lay the view out on.
  ///   - orientation: The orientation the tablet is held in. Defaults to landscape.
  public static func iPad(
    _ generation: TabletGeneration,
    _ orientation: Orientation = .landscape
  ) -> Self {
    let screen = generation.screen
    let size: CGSize
    switch orientation {
    case .landscape: size = CGSize(width: screen.longSide, height: screen.shortSide)
    case .portrait: size = CGSize(width: screen.shortSide, height: screen.longSide)
    }
    return Self(
      safeArea: screen.safeArea.insets,
      size: size,
      traits: { traits in
        traits.horizontalSizeClass = .regular
        traits.verticalSizeClass = .regular
        traits.userInterfaceIdiom = .pad
      }
    )
  }
}

/// The measurements of an iPad screen. An iPad is regular in both dimensions in either orientation.
private struct TabletScreen {
  /// The height of the screen in landscape, which is its width in portrait.
  var shortSide: CGFloat
  /// The width of the screen in landscape, which is its height in portrait.
  var longSide: CGFloat
  /// The chrome around the screen, which decides the insets it reserves.
  var safeArea: TabletSafeArea
}

extension DeviceProfile.TabletGeneration {
  fileprivate var screen: TabletScreen {
    switch self {
    case .year2010:
      TabletScreen(shortSide: 768, longSide: 1024, safeArea: .homeButton)
    case .year2015:
      TabletScreen(shortSide: 1024, longSide: 1366, safeArea: .homeButton)
    case .year2017:
      TabletScreen(shortSide: 834, longSide: 1112, safeArea: .homeButton)
    case .year2018:
      TabletScreen(shortSide: 834, longSide: 1194, safeArea: .homeIndicator)
    case .year2019:
      TabletScreen(shortSide: 810, longSide: 1080, safeArea: .homeButton)
    }
  }
}
#endif
