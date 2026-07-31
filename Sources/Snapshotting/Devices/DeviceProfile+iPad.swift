#if os(iOS)
import UIKit

extension DeviceProfile {
  /// A family of iPads that share a screen.
  ///
  /// Cases are named for the year their screen first shipped.
  public enum TabletGeneration: Sendable {
    /// 1024 × 768 pt — iPad (1st–6th generation), iPad 9.7", iPad Air, Air 2, iPad mini (1st–5th generation).
    case year2010

    /// 1366 × 1024 pt — iPad Pro 12.9" (1st–6th generation), iPad Air 13" (M2, M3, M4).
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
  /// - Parameters:
  ///   - generation: The family of iPads to lay the view out on.
  ///   - orientation: The orientation the tablet is held in, and the share of the screen the view
  ///     occupies. Defaults to landscape, occupying the whole screen.
  public static func iPad(
    _ generation: TabletGeneration,
    _ orientation: TabletOrientation = .landscape
  ) -> Self {
    let screen = generation.screen
    let size: CGSize
    let split: SplitView
    switch orientation {
    case .landscape(let splitView):
      switch splitView {
      case .oneThird: split = screen.landscape.oneThird
      case .oneHalf: split = screen.landscape.oneHalf
      case .twoThirds: split = screen.landscape.twoThirds
      case .full: split = .regular(screen.longSide)
      }
      size = CGSize(width: split.width, height: screen.shortSide)
    case .portrait(let splitView):
      switch splitView {
      case .oneThird: split = screen.portrait.oneThird
      case .twoThirds: split = screen.portrait.twoThirds
      case .full: split = .regular(screen.shortSide)
      }
      size = CGSize(width: split.width, height: screen.longSide)
    }
    return Self(
      safeArea: screen.safeArea,
      size: size,
      traits: { traits in
        traits.horizontalSizeClass = split.horizontalSizeClass
        traits.verticalSizeClass = .regular
        traits.userInterfaceIdiom = .pad
      }
    )
  }
}

/// The width of one split-view arrangement, and the horizontal size class the app reports at that
/// width.
private struct SplitView {
  var width: CGFloat
  var horizontalSizeClass: UIUserInterfaceSizeClass

  static func compact(_ width: CGFloat) -> Self {
    Self(width: width, horizontalSizeClass: .compact)
  }

  static func regular(_ width: CGFloat) -> Self {
    Self(width: width, horizontalSizeClass: .regular)
  }
}

/// The measurements of an iPad screen. An iPad is vertically regular in either orientation, so only
/// the width of a split view varies.
private struct TabletScreen {
  /// The height of the screen in landscape, which is its width in portrait.
  var shortSide: CGFloat
  /// The width of the screen in landscape, which is its height in portrait.
  var longSide: CGFloat
  var safeArea: UIEdgeInsets
  var landscape: (oneThird: SplitView, oneHalf: SplitView, twoThirds: SplitView)
  var portrait: (oneThird: SplitView, twoThirds: SplitView)
}

extension DeviceProfile.TabletGeneration {
  fileprivate var screen: TabletScreen {
    switch self {
    case .year2010:
      TabletScreen(
        shortSide: 768,
        longSide: 1024,
        safeArea: UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0),
        landscape: (.compact(320), .compact(507), .regular(694)),
        portrait: (.compact(320), .compact(438))
      )
    case .year2015:
      TabletScreen(
        shortSide: 1024,
        longSide: 1366,
        safeArea: UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0),
        landscape: (.compact(375), .regular(678), .regular(981)),
        portrait: (.compact(375), .compact(639))
      )
    case .year2017:
      TabletScreen(
        shortSide: 834,
        longSide: 1112,
        safeArea: UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0),
        landscape: (.compact(320), .compact(551), .regular(782)),
        portrait: (.compact(320), .compact(504))
      )
    case .year2018:
      TabletScreen(
        shortSide: 834,
        longSide: 1194,
        safeArea: UIEdgeInsets(top: 24, left: 0, bottom: 20, right: 0),
        landscape: (.compact(375), .compact(592), .regular(809)),
        portrait: (.compact(320), .compact(504))
      )
    case .year2019:
      TabletScreen(
        shortSide: 810,
        longSide: 1080,
        safeArea: UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0),
        landscape: (.compact(320), .compact(535), .regular(750)),
        portrait: (.compact(320), .compact(480))
      )
    }
  }
}
#endif
