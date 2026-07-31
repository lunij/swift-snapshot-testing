#if os(iOS)
import UIKit

/// The insets an iPhone screen reserves for the chrome around it, as the running system lays them
/// out.
///
/// A screen reserves room for what surrounds it rather than for its own size, so the chrome names
/// what a screen has and the system decides how deep it is.
enum PhoneSafeArea {
  /// A screen a home button frames. The status bar spans the top in portrait, and the system hides
  /// it in landscape.
  case homeButton

  /// A screen a sensor housing interrupts, with a home indicator below it.
  ///
  /// - Parameter depth: How far the housing reaches into the screen, in points. It reaches that far
  ///   from the top in portrait, and from each side in landscape.
  case sensorHousing(depth: CGFloat)

  /// The insets the screen reserves in the given orientation.
  func insets(_ orientation: DeviceProfile.Orientation) -> UIEdgeInsets {
    switch (self, orientation) {
    case (.homeButton, .portrait):
      UIEdgeInsets(top: SafeArea.statusBar, left: 0, bottom: 0, right: 0)
    case (.homeButton, .landscape):
      .zero
    case (.sensorHousing(let depth), .portrait):
      UIEdgeInsets(top: depth, left: 0, bottom: SafeArea.homeIndicator, right: 0)
    case (.sensorHousing(let depth), .landscape):
      UIEdgeInsets(
        top: 0,
        left: depth,
        bottom: SafeArea.landscapeHomeIndicator,
        right: depth
      )
    }
  }
}

/// The insets an iPad screen reserves for the chrome around it, as the running system lays them out.
///
/// An iPad reserves the same insets in either orientation.
enum TabletSafeArea {
  /// A screen a home button frames, with the status bar spanning the top.
  case homeButton

  /// A screen with a home indicator below it, and a status bar deeper than a home button leaves
  /// room for.
  case homeIndicator

  /// The insets the screen reserves.
  var insets: UIEdgeInsets {
    switch self {
    case .homeButton:
      UIEdgeInsets(top: SafeArea.statusBar, left: 0, bottom: 0, right: 0)
    case .homeIndicator:
      UIEdgeInsets(
        top: SafeArea.tabletStatusBar,
        left: 0,
        bottom: SafeArea.tabletHomeIndicator,
        right: 0
      )
    }
  }
}

/// How deep the system draws each piece of chrome, in points.
///
/// These depths belong to the system rather than to a device: iOS 26 gives the iPad status bar 32
/// points where earlier releases give it 24, and gives the iPhone's landscape home indicator 20
/// points where earlier releases give it 21.
private enum SafeArea {
  /// The status bar above a screen a home button frames.
  static let statusBar: CGFloat = 20

  /// The status bar above an iPad screen with a home indicator.
  static var tabletStatusBar: CGFloat {
    if #available(iOS 26, *) { 32 } else { 24 }
  }

  /// The home indicator below an iPad screen.
  static let tabletHomeIndicator: CGFloat = 25

  /// The home indicator below a portrait iPhone screen.
  static let homeIndicator: CGFloat = 34

  /// The home indicator below a landscape iPhone screen, which the system draws slimmer than it
  /// does in portrait.
  static var landscapeHomeIndicator: CGFloat {
    if #available(iOS 26, *) { 20 } else { 21 }
  }
}
#endif
