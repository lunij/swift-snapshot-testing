#if os(iOS)
import UIKit

extension DeviceProfile {
  /// A family of iPads that share a screen.
  ///
  /// Cases are named for the year their screen first shipped; a size role distinguishes the years
  /// that introduced more than one.
  ///
  /// A screen is named here for as long as at least one model that ships it runs the lowest iOS
  /// this package supports. Screens no reachable device has are left out; lay a view out on one by
  /// passing its size directly.
  public enum TabletGeneration: Sendable {
    /// 1024 × 768 pt — iPad (1st–6th generation), iPad 9.7", iPad Air, Air 2, iPad mini (1st–5th generation).
    case year2010

    /// 1112 × 834 pt — iPad Pro 10.5", iPad Air (3rd generation).
    case year2017

    /// 1194 × 834 pt — iPad Pro 11" (1st–4th generation).
    case year2018

    /// 1366 × 1024 pt — iPad Pro 12.9" (3rd–6th generation), iPad Air 13" (M2, M3, M4).
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

    /// The family, then the models that ship its screen, a line each.
    ///
    /// Deliberately not a `CustomStringConvertible` conformance: `String(describing:)` has to keep
    /// returning the bare case name, which is what a test names a reference file after.
    public var description: String { self.screen.description }
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

/// An iPad screen: the models that ship it, and the measurements they share. An iPad is regular in
/// both dimensions in either orientation.
private struct TabletScreen {
  /// The family, then the models that ship this screen, a line each.
  var description: String
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
      TabletScreen(
        description: """
          iPad .year2010
          iPad (1st–6th generation), iPad 9.7", iPad Air, Air 2, iPad mini (1st–5th generation)
          """,
        shortSide: 768,
        longSide: 1024,
        safeArea: .homeButton
      )
    case .year2017:
      TabletScreen(
        description: """
          iPad .year2017
          iPad Pro 10.5", iPad Air (3rd generation)
          """,
        shortSide: 834,
        longSide: 1112,
        safeArea: .homeButton
      )
    case .year2018:
      TabletScreen(
        description: """
          iPad .year2018
          iPad Pro 11" (1st–4th generation)
          """,
        shortSide: 834,
        longSide: 1194,
        safeArea: .homeIndicator
      )
    case .year2018Large:
      TabletScreen(
        description: """
          iPad .year2018Large
          iPad Pro 12.9" (3rd–6th generation), iPad Air 13" (M2, M3, M4)
          """,
        shortSide: 1024,
        longSide: 1366,
        safeArea: .homeIndicator
      )
    case .year2019:
      TabletScreen(
        description: """
          iPad .year2019
          iPad (7th, 8th, 9th generation), iPad 10.2"
          """,
        shortSide: 810,
        longSide: 1080,
        safeArea: .homeButton
      )
    case .year2020:
      TabletScreen(
        description: """
          iPad .year2020
          iPad Air 10.9" (4th, 5th generation), iPad (10th generation), iPad (A16), iPad Air 11" (M2, M3, M4)
          """,
        shortSide: 820,
        longSide: 1180,
        safeArea: .homeIndicator
      )
    case .year2021:
      TabletScreen(
        description: """
          iPad .year2021
          iPad mini (6th generation), iPad mini (A17 Pro)
          """,
        shortSide: 744,
        longSide: 1133,
        safeArea: .homeIndicator
      )
    case .year2024:
      TabletScreen(
        description: """
          iPad .year2024
          iPad Pro 11" (M4, M5)
          """,
        shortSide: 834,
        longSide: 1210,
        safeArea: .homeIndicator
      )
    case .year2024Large:
      TabletScreen(
        description: """
          iPad .year2024Large
          iPad Pro 13" (M4, M5)
          """,
        shortSide: 1032,
        longSide: 1376,
        safeArea: .homeIndicator
      )
    }
  }
}
#endif
