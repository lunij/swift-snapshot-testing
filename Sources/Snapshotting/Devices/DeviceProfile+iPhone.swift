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

    /// 390 × 844 pt — iPhone 12, 12 Pro, 13, 13 Pro, 14.
    case year2020

    /// 428 × 926 pt — iPhone 12 Pro Max, 13 Pro Max, 14 Plus.
    case year2020Max
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
    let safeArea: UIEdgeInsets
    let horizontalSizeClass: UIUserInterfaceSizeClass
    let verticalSizeClass: UIUserInterfaceSizeClass
    switch orientation {
    case .landscape:
      size = CGSize(width: screen.portraitSize.height, height: screen.portraitSize.width)
      safeArea = screen.landscapeSafeArea
      horizontalSizeClass = screen.landscapeHorizontalSizeClass
      verticalSizeClass = .compact
    case .portrait:
      size = screen.portraitSize
      safeArea = screen.portraitSafeArea
      horizontalSizeClass = .compact
      verticalSizeClass = .regular
    }
    return Self(
      safeArea: safeArea,
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

/// The measurements of an iPhone screen, held in portrait.
private struct PhoneScreen {
  var portraitSize: CGSize
  var portraitSafeArea: UIEdgeInsets
  var landscapeSafeArea: UIEdgeInsets
  /// The horizontal size class the phone reports in landscape. Every iPhone is horizontally
  /// compact in portrait.
  var landscapeHorizontalSizeClass: UIUserInterfaceSizeClass
}

extension DeviceProfile.PhoneGeneration {
  fileprivate var screen: PhoneScreen {
    switch self {
    case .year2012:
      PhoneScreen(
        portraitSize: CGSize(width: 320, height: 568),
        portraitSafeArea: UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0),
        landscapeSafeArea: .zero,
        landscapeHorizontalSizeClass: .compact
      )
    case .year2014:
      PhoneScreen(
        portraitSize: CGSize(width: 375, height: 667),
        portraitSafeArea: UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0),
        landscapeSafeArea: .zero,
        landscapeHorizontalSizeClass: .compact
      )
    case .year2014Plus:
      PhoneScreen(
        portraitSize: CGSize(width: 414, height: 736),
        portraitSafeArea: UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0),
        landscapeSafeArea: .zero,
        landscapeHorizontalSizeClass: .regular
      )
    case .year2017:
      PhoneScreen(
        portraitSize: CGSize(width: 375, height: 812),
        portraitSafeArea: UIEdgeInsets(top: 44, left: 0, bottom: 34, right: 0),
        landscapeSafeArea: UIEdgeInsets(top: 0, left: 44, bottom: 24, right: 44),
        landscapeHorizontalSizeClass: .compact
      )
    case .year2018:
      PhoneScreen(
        portraitSize: CGSize(width: 414, height: 896),
        portraitSafeArea: UIEdgeInsets(top: 44, left: 0, bottom: 34, right: 0),
        landscapeSafeArea: UIEdgeInsets(top: 0, left: 44, bottom: 24, right: 44),
        landscapeHorizontalSizeClass: .regular
      )
    case .year2020Mini:
      PhoneScreen(
        portraitSize: CGSize(width: 375, height: 812),
        portraitSafeArea: UIEdgeInsets(top: 50, left: 0, bottom: 34, right: 0),
        landscapeSafeArea: UIEdgeInsets(top: 0, left: 50, bottom: 21, right: 50),
        landscapeHorizontalSizeClass: .compact
      )
    case .year2020:
      PhoneScreen(
        portraitSize: CGSize(width: 390, height: 844),
        portraitSafeArea: UIEdgeInsets(top: 47, left: 0, bottom: 34, right: 0),
        landscapeSafeArea: UIEdgeInsets(top: 0, left: 47, bottom: 21, right: 47),
        landscapeHorizontalSizeClass: .compact
      )
    case .year2020Max:
      PhoneScreen(
        portraitSize: CGSize(width: 428, height: 926),
        portraitSafeArea: UIEdgeInsets(top: 47, left: 0, bottom: 34, right: 0),
        landscapeSafeArea: UIEdgeInsets(top: 0, left: 47, bottom: 21, right: 47),
        landscapeHorizontalSizeClass: .regular
      )
    }
  }
}
#endif
