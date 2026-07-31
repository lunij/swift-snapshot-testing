#if os(iOS)
import UIKit

extension DeviceProfile {
  /// A family of iPads that share a screen.
  ///
  /// Cases are named for the year their screen first shipped; a size role distinguishes the years
  /// that introduced more than one.
  public enum TabletGeneration: Sendable {
    /// 1024 × 768 pt — iPad (1st–6th generation), iPad 9.7", iPad Air, Air 2, iPad mini (1st–5th generation).
    case year2010

    /// 1366 × 1024 pt — iPad Pro 12.9" (1st, 2nd generation).
    case year2015

    /// 1112 × 834 pt — iPad Pro 10.5", iPad Air (3rd generation).
    case year2017

    /// 1194 × 834 pt — iPad Pro 11" (1st–4th generation).
    case year2018

    /// 1366 × 1024 pt — iPad Pro 12.9" (3rd–6th generation), iPad Air 13" (M2, M3, M4).
    ///
    /// The same size as ``year2015``, below a home indicator rather than beside a home button, so
    /// it reserves different insets.
    case year2018Large

    /// 1080 × 810 pt — iPad (7th, 8th, 9th generation), iPad 10.2".
    case year2019

    /// 1180 × 820 pt — iPad Air 10.9" (4th, 5th generation), iPad (10th generation), iPad (A16),
    /// iPad Air 11" (M2, M3, M4).
    case year2020

    /// 1133 × 744 pt — iPad mini (6th generation), iPad mini (A17 Pro).
    case year2021

    /// 1210 × 834 pt — iPad Pro 11" (M4, M5).
    case year2024

    /// 1376 × 1032 pt — iPad Pro 13" (M4, M5).
    case year2024Large
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
    case .year2018Large:
      TabletScreen(shortSide: 1024, longSide: 1366, safeArea: .homeIndicator)
    case .year2019:
      TabletScreen(shortSide: 810, longSide: 1080, safeArea: .homeButton)
    case .year2020:
      TabletScreen(shortSide: 820, longSide: 1180, safeArea: .homeIndicator)
    case .year2021:
      TabletScreen(shortSide: 744, longSide: 1133, safeArea: .homeIndicator)
    case .year2024:
      TabletScreen(shortSide: 834, longSide: 1210, safeArea: .homeIndicator)
    case .year2024Large:
      TabletScreen(shortSide: 1032, longSide: 1376, safeArea: .homeIndicator)
    }
  }
}
#endif
