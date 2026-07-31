#if os(iOS)
import UIKit

extension DeviceProfile {
  /// A family of iPhones that share a screen.
  ///
  /// Cases are named for the year their screen first shipped; a size role distinguishes the years
  /// that introduced more than one.
  public enum PhoneGeneration: Sendable {
    /// 320 × 568 pt — iPhone 5, 5c, 5s, iPhone SE (1st generation), iPod touch (6th, 7th
    /// generation).
    case year2012

    /// 375 × 667 pt — iPhone 6, 6s, 7, 8, iPhone SE (2nd, 3rd generation).
    case year2014

    /// 414 × 736 pt — iPhone 6 Plus, 6s Plus, 7 Plus, 8 Plus.
    case year2014Plus

    /// 375 × 812 pt — iPhone X, XS, 11 Pro.
    case year2017

    /// 414 × 896 pt — iPhone XR, XS Max, 11, 11 Pro Max.
    case year2018

    /// 375 × 812 pt with a taller sensor housing — iPhone 12 mini, 13 mini.
    case year2020Mini

    /// 390 × 844 pt — iPhone 12, 12 Pro, 13, 13 Pro, 14, 16e, 17e.
    case year2020

    /// 428 × 926 pt — iPhone 12 Pro Max, 13 Pro Max, 14 Plus.
    case year2020Max

    /// 393 × 852 pt — iPhone 14 Pro, 15, 15 Pro, 16.
    case year2022

    /// 430 × 932 pt — iPhone 14 Pro Max, 15 Plus, 15 Pro Max, 16 Plus.
    case year2022Max

    /// 402 × 874 pt — iPhone 16 Pro, 17, 17 Pro.
    case year2024

    /// 440 × 956 pt — iPhone 16 Pro Max, 17 Pro Max.
    case year2024Max

    /// 420 × 912 pt — iPhone Air.
    case year2025Air

    /// The family, then the models that ship its screen, a line each.
    ///
    /// Deliberately not a `CustomStringConvertible` conformance: `String(describing:)` has to keep
    /// returning the bare case name, which is what a test names a reference file after.
    public var description: String { self.screen.description }
  }

  /// A profile for an iPhone screen.
  ///
  /// - Parameters:
  ///   - generation: The family of iPhones to lay the view out on.
  ///   - orientation: The orientation the phone is held in. Defaults to portrait.
  public static func iPhone(
    _ generation: PhoneGeneration,
    _ orientation: Orientation = .portrait
  ) -> Self {
    let screen = generation.screen
    let size: CGSize
    let horizontalSizeClass: UIUserInterfaceSizeClass
    let verticalSizeClass: UIUserInterfaceSizeClass
    switch orientation {
    case .landscape:
      size = CGSize(width: screen.portraitSize.height, height: screen.portraitSize.width)
      horizontalSizeClass = screen.landscapeHorizontalSizeClass
      verticalSizeClass = .compact
    case .portrait:
      size = screen.portraitSize
      horizontalSizeClass = .compact
      verticalSizeClass = .regular
    }
    return Self(
      safeArea: screen.safeArea.insets(orientation),
      size: size,
      traits: { traits in
        traits.forceTouchCapability = .available
        traits.layoutDirection = .leftToRight
        traits.preferredContentSizeCategory = .medium
        traits.userInterfaceIdiom = .phone
        traits.horizontalSizeClass = horizontalSizeClass
        traits.verticalSizeClass = verticalSizeClass
      }
    )
  }
}

/// An iPhone screen: the models that ship it, and the measurements they share, held in portrait.
private struct PhoneScreen {
  /// The family, then the models that ship this screen, a line each.
  var description: String
  var portraitSize: CGSize
  /// The chrome around the screen, which decides the insets it reserves.
  var safeArea: PhoneSafeArea
  /// The horizontal size class the phone reports in landscape. Every iPhone is horizontally
  /// compact in portrait.
  var landscapeHorizontalSizeClass: UIUserInterfaceSizeClass
}

extension DeviceProfile.PhoneGeneration {
  fileprivate var screen: PhoneScreen {
    switch self {
    case .year2012:
      PhoneScreen(
        description: """
          iPhone .year2012
          iPhone 5, 5c, 5s, iPhone SE (1st generation), iPod touch (6th, 7th generation)
          """,
        portraitSize: CGSize(width: 320, height: 568),
        safeArea: .homeButton,
        landscapeHorizontalSizeClass: .compact
      )
    case .year2014:
      PhoneScreen(
        description: """
          iPhone .year2014
          iPhone 6, 6s, 7, 8, iPhone SE (2nd, 3rd generation)
          """,
        portraitSize: CGSize(width: 375, height: 667),
        safeArea: .homeButton,
        landscapeHorizontalSizeClass: .compact
      )
    case .year2014Plus:
      PhoneScreen(
        description: """
          iPhone .year2014Plus
          iPhone 6 Plus, 6s Plus, 7 Plus, 8 Plus
          """,
        portraitSize: CGSize(width: 414, height: 736),
        safeArea: .homeButton,
        landscapeHorizontalSizeClass: .regular
      )
    case .year2017:
      PhoneScreen(
        description: """
          iPhone .year2017
          iPhone X, XS, 11 Pro
          """,
        portraitSize: CGSize(width: 375, height: 812),
        safeArea: .sensorHousing(depth: 44),
        landscapeHorizontalSizeClass: .compact
      )
    case .year2018:
      PhoneScreen(
        description: """
          iPhone .year2018
          iPhone XR, XS Max, 11, 11 Pro Max
          """,
        portraitSize: CGSize(width: 414, height: 896),
        safeArea: .sensorHousing(depth: 44),
        landscapeHorizontalSizeClass: .regular
      )
    case .year2020Mini:
      PhoneScreen(
        description: """
          iPhone .year2020Mini
          iPhone 12 mini, 13 mini
          """,
        portraitSize: CGSize(width: 375, height: 812),
        safeArea: .sensorHousing(depth: 50),
        landscapeHorizontalSizeClass: .compact
      )
    case .year2020:
      PhoneScreen(
        description: """
          iPhone .year2020
          iPhone 12, 12 Pro, 13, 13 Pro, 14, 16e, 17e
          """,
        portraitSize: CGSize(width: 390, height: 844),
        safeArea: .sensorHousing(depth: 47),
        landscapeHorizontalSizeClass: .compact
      )
    case .year2020Max:
      PhoneScreen(
        description: """
          iPhone .year2020Max
          iPhone 12 Pro Max, 13 Pro Max, 14 Plus
          """,
        portraitSize: CGSize(width: 428, height: 926),
        safeArea: .sensorHousing(depth: 47),
        landscapeHorizontalSizeClass: .regular
      )
    case .year2022:
      PhoneScreen(
        description: """
          iPhone .year2022
          iPhone 14 Pro, 15, 15 Pro, 16
          """,
        portraitSize: CGSize(width: 393, height: 852),
        safeArea: .sensorHousing(depth: 59),
        landscapeHorizontalSizeClass: .compact
      )
    case .year2022Max:
      PhoneScreen(
        description: """
          iPhone .year2022Max
          iPhone 14 Pro Max, 15 Plus, 15 Pro Max, 16 Plus
          """,
        portraitSize: CGSize(width: 430, height: 932),
        safeArea: .sensorHousing(depth: 59),
        landscapeHorizontalSizeClass: .regular
      )
    case .year2024:
      PhoneScreen(
        description: """
          iPhone .year2024
          iPhone 16 Pro, 17, 17 Pro
          """,
        portraitSize: CGSize(width: 402, height: 874),
        safeArea: .sensorHousing(depth: 62),
        landscapeHorizontalSizeClass: .compact
      )
    case .year2024Max:
      PhoneScreen(
        description: """
          iPhone .year2024Max
          iPhone 16 Pro Max, 17 Pro Max
          """,
        portraitSize: CGSize(width: 440, height: 956),
        safeArea: .sensorHousing(depth: 62),
        landscapeHorizontalSizeClass: .regular
      )
    case .year2025Air:
      PhoneScreen(
        description: """
          iPhone .year2025Air
          iPhone Air
          """,
        portraitSize: CGSize(width: 420, height: 912),
        safeArea: .sensorHousing(depth: 68),
        landscapeHorizontalSizeClass: .regular
      )
    }
  }
}
#endif
