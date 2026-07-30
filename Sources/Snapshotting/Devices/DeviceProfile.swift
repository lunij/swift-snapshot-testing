#if os(iOS) || os(tvOS)
import UIKit

/// The screen a view is laid out and rendered on.
///
/// A profile describes a device: the size of its screen in points, the insets its safe area
/// reserves, the scale it renders at, and the traits it reports — its idiom, its size classes, and
/// its input capabilities.
public struct DeviceProfile: Sendable {
  public enum Orientation: Sendable {
    case landscape
    case portrait
  }
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

  #if os(iOS)
  public static let iPhoneSe = DeviceProfile.iPhoneSe(.portrait)

  public static func iPhoneSe(_ orientation: Orientation) -> DeviceProfile {
    let safeArea: UIEdgeInsets
    let size: CGSize
    switch orientation {
    case .landscape:
      safeArea = .zero
      size = .init(width: 568, height: 320)
    case .portrait:
      safeArea = .init(top: 20, left: 0, bottom: 0, right: 0)
      size = .init(width: 320, height: 568)
    }
    return .init(safeArea: safeArea, size: size, traits: iPhoneSeTraits(orientation))
  }

  public static let iPhone8 = DeviceProfile.iPhone8(.portrait)

  public static func iPhone8(_ orientation: Orientation) -> DeviceProfile {
    let safeArea: UIEdgeInsets
    let size: CGSize
    switch orientation {
    case .landscape:
      safeArea = .zero
      size = .init(width: 667, height: 375)
    case .portrait:
      safeArea = .init(top: 20, left: 0, bottom: 0, right: 0)
      size = .init(width: 375, height: 667)
    }
    return .init(safeArea: safeArea, size: size, traits: iPhone8Traits(orientation))
  }

  public static let iPhone8Plus = DeviceProfile.iPhone8Plus(.portrait)

  public static func iPhone8Plus(_ orientation: Orientation) -> DeviceProfile {
    let safeArea: UIEdgeInsets
    let size: CGSize
    switch orientation {
    case .landscape:
      safeArea = .zero
      size = .init(width: 736, height: 414)
    case .portrait:
      safeArea = .init(top: 20, left: 0, bottom: 0, right: 0)
      size = .init(width: 414, height: 736)
    }
    return .init(safeArea: safeArea, size: size, traits: iPhone8PlusTraits(orientation))
  }

  public static let iPhoneX = DeviceProfile.iPhoneX(.portrait)

  public static func iPhoneX(_ orientation: Orientation) -> DeviceProfile {
    let safeArea: UIEdgeInsets
    let size: CGSize
    switch orientation {
    case .landscape:
      safeArea = .init(top: 0, left: 44, bottom: 24, right: 44)
      size = .init(width: 812, height: 375)
    case .portrait:
      safeArea = .init(top: 44, left: 0, bottom: 34, right: 0)
      size = .init(width: 375, height: 812)
    }
    return .init(safeArea: safeArea, size: size, traits: iPhoneXTraits(orientation))
  }

  public static let iPhoneXsMax = DeviceProfile.iPhoneXsMax(.portrait)

  public static func iPhoneXsMax(_ orientation: Orientation) -> DeviceProfile {
    let safeArea: UIEdgeInsets
    let size: CGSize
    switch orientation {
    case .landscape:
      safeArea = .init(top: 0, left: 44, bottom: 24, right: 44)
      size = .init(width: 896, height: 414)
    case .portrait:
      safeArea = .init(top: 44, left: 0, bottom: 34, right: 0)
      size = .init(width: 414, height: 896)
    }
    return .init(safeArea: safeArea, size: size, traits: iPhoneXsMaxTraits(orientation))
  }

  @available(iOS 11.0, *)
  public static let iPhoneXr = DeviceProfile.iPhoneXr(.portrait)

  @available(iOS 11.0, *)
  public static func iPhoneXr(_ orientation: Orientation) -> DeviceProfile {
    let safeArea: UIEdgeInsets
    let size: CGSize
    switch orientation {
    case .landscape:
      safeArea = .init(top: 0, left: 44, bottom: 24, right: 44)
      size = .init(width: 896, height: 414)
    case .portrait:
      safeArea = .init(top: 44, left: 0, bottom: 34, right: 0)
      size = .init(width: 414, height: 896)
    }
    return .init(safeArea: safeArea, size: size, traits: iPhoneXrTraits(orientation))
  }

  public static let iPhone12 = DeviceProfile.iPhone12(.portrait)

  public static func iPhone12(_ orientation: Orientation) -> DeviceProfile {
    let safeArea: UIEdgeInsets
    let size: CGSize
    switch orientation {
    case .landscape:
      safeArea = .init(top: 0, left: 47, bottom: 21, right: 47)
      size = .init(width: 844, height: 390)
    case .portrait:
      safeArea = .init(top: 47, left: 0, bottom: 34, right: 0)
      size = .init(width: 390, height: 844)
    }
    return .init(safeArea: safeArea, size: size, traits: iPhone12Traits(orientation))
  }

  public static let iPhone12Pro = DeviceProfile.iPhone12Pro(.portrait)

  public static func iPhone12Pro(_ orientation: Orientation) -> DeviceProfile {
    .iPhone12(orientation)
  }

  public static let iPhone12ProMax = DeviceProfile.iPhone12ProMax(.portrait)

  public static func iPhone12ProMax(_ orientation: Orientation) -> DeviceProfile {
    let safeArea: UIEdgeInsets
    let size: CGSize
    switch orientation {
    case .landscape:
      safeArea = .init(top: 0, left: 47, bottom: 21, right: 47)
      size = .init(width: 926, height: 428)
    case .portrait:
      safeArea = .init(top: 47, left: 0, bottom: 34, right: 0)
      size = .init(width: 428, height: 926)
    }
    return .init(safeArea: safeArea, size: size, traits: iPhone12ProMaxTraits(orientation))
  }

  public static let iPhone13 = DeviceProfile.iPhone13(.portrait)

  public static func iPhone13(_ orientation: Orientation) -> DeviceProfile {
    let safeArea: UIEdgeInsets
    let size: CGSize
    switch orientation {
    case .landscape:
      safeArea = .init(top: 0, left: 47, bottom: 21, right: 47)
      size = .init(width: 844, height: 390)
    case .portrait:
      safeArea = .init(top: 47, left: 0, bottom: 34, right: 0)
      size = .init(width: 390, height: 844)
    }

    return .init(
      safeArea: safeArea,
      size: size,
      traits: iPhone13Traits(orientation)
    )
  }

  public static let iPhone13Mini = DeviceProfile.iPhone13Mini(.portrait)

  public static func iPhone13Mini(_ orientation: Orientation) -> DeviceProfile {
    let safeArea: UIEdgeInsets
    let size: CGSize
    switch orientation {
    case .landscape:
      safeArea = .init(top: 0, left: 50, bottom: 21, right: 50)
      size = .init(width: 812, height: 375)
    case .portrait:
      safeArea = .init(top: 50, left: 0, bottom: 34, right: 0)
      size = .init(width: 375, height: 812)
    }

    return .init(safeArea: safeArea, size: size, traits: iPhone13Traits(orientation))
  }

  public static let iPhone13Pro = DeviceProfile.iPhone13Pro(.portrait)

  public static func iPhone13Pro(_ orientation: Orientation) -> DeviceProfile {
    .iPhone13(orientation)
  }

  public static let iPhone13ProMax = DeviceProfile.iPhone13ProMax(.portrait)

  public static func iPhone13ProMax(_ orientation: Orientation) -> DeviceProfile {
    let safeArea: UIEdgeInsets
    let size: CGSize
    switch orientation {
    case .landscape:
      safeArea = .init(top: 0, left: 47, bottom: 21, right: 47)
      size = .init(width: 926, height: 428)
    case .portrait:
      safeArea = .init(top: 47, left: 0, bottom: 34, right: 0)
      size = .init(width: 428, height: 926)
    }

    return .init(safeArea: safeArea, size: size, traits: iPhone13ProMaxTraits(orientation))
  }

  public static let iPadMini = DeviceProfile.iPadMini(.landscape)

  public static func iPadMini(_ orientation: Orientation) -> DeviceProfile {
    switch orientation {
    case .landscape:
      return DeviceProfile.iPadMini(.landscape(splitView: .full))
    case .portrait:
      return DeviceProfile.iPadMini(.portrait(splitView: .full))
    }
  }

  public static func iPadMini(_ orientation: TabletOrientation) -> DeviceProfile {
    let size: CGSize
    let traits: TraitMutations
    switch orientation {
    case .landscape(let splitView):
      switch splitView {
      case .oneThird:
        size = .init(width: 320, height: 768)
        traits = iPadCompactSplitViewTraits
      case .oneHalf:
        size = .init(width: 507, height: 768)
        traits = iPadCompactSplitViewTraits
      case .twoThirds:
        size = .init(width: 694, height: 768)
        traits = iPadTraits
      case .full:
        size = .init(width: 1024, height: 768)
        traits = iPadTraits
      }
    case .portrait(let splitView):
      switch splitView {
      case .oneThird:
        size = .init(width: 320, height: 1024)
        traits = iPadCompactSplitViewTraits
      case .twoThirds:
        size = .init(width: 438, height: 1024)
        traits = iPadCompactSplitViewTraits
      case .full:
        size = .init(width: 768, height: 1024)
        traits = iPadTraits
      }
    }
    return .init(
      safeArea: .init(top: 20, left: 0, bottom: 0, right: 0),
      size: size,
      traits: traits
    )
  }

  public static let iPad9_7 = iPadMini

  public static func iPad9_7(_ orientation: Orientation) -> DeviceProfile {
    iPadMini(orientation)
  }

  public static func iPad9_7(_ orientation: TabletOrientation) -> DeviceProfile {
    iPadMini(orientation)
  }

  public static let iPad10_2 = DeviceProfile.iPad10_2(.landscape)

  public static func iPad10_2(_ orientation: Orientation) -> DeviceProfile {
    switch orientation {
    case .landscape:
      return DeviceProfile.iPad10_2(.landscape(splitView: .full))
    case .portrait:
      return DeviceProfile.iPad10_2(.portrait(splitView: .full))
    }
  }

  public static func iPad10_2(_ orientation: TabletOrientation) -> DeviceProfile {
    let size: CGSize
    let traits: TraitMutations
    switch orientation {
    case .landscape(let splitView):
      switch splitView {
      case .oneThird:
        size = .init(width: 320, height: 810)
        traits = iPadCompactSplitViewTraits
      case .oneHalf:
        size = .init(width: 535, height: 810)
        traits = iPadCompactSplitViewTraits
      case .twoThirds:
        size = .init(width: 750, height: 810)
        traits = iPadTraits
      case .full:
        size = .init(width: 1080, height: 810)
        traits = iPadTraits
      }
    case .portrait(let splitView):
      switch splitView {
      case .oneThird:
        size = .init(width: 320, height: 1080)
        traits = iPadCompactSplitViewTraits
      case .twoThirds:
        size = .init(width: 480, height: 1080)
        traits = iPadCompactSplitViewTraits
      case .full:
        size = .init(width: 810, height: 1080)
        traits = iPadTraits
      }
    }
    return .init(
      safeArea: .init(top: 20, left: 0, bottom: 0, right: 0),
      size: size,
      traits: traits
    )
  }

  public static let iPadPro10_5 = DeviceProfile.iPadPro10_5(.landscape)

  public static func iPadPro10_5(_ orientation: Orientation) -> DeviceProfile {
    switch orientation {
    case .landscape:
      return DeviceProfile.iPadPro10_5(.landscape(splitView: .full))
    case .portrait:
      return DeviceProfile.iPadPro10_5(.portrait(splitView: .full))
    }
  }

  public static func iPadPro10_5(_ orientation: TabletOrientation) -> DeviceProfile {
    let size: CGSize
    let traits: TraitMutations
    switch orientation {
    case .landscape(let splitView):
      switch splitView {
      case .oneThird:
        size = .init(width: 320, height: 834)
        traits = iPadCompactSplitViewTraits
      case .oneHalf:
        size = .init(width: 551, height: 834)
        traits = iPadCompactSplitViewTraits
      case .twoThirds:
        size = .init(width: 782, height: 834)
        traits = iPadTraits
      case .full:
        size = .init(width: 1112, height: 834)
        traits = iPadTraits
      }
    case .portrait(let splitView):
      switch splitView {
      case .oneThird:
        size = .init(width: 320, height: 1112)
        traits = iPadCompactSplitViewTraits
      case .twoThirds:
        size = .init(width: 504, height: 1112)
        traits = iPadCompactSplitViewTraits
      case .full:
        size = .init(width: 834, height: 1112)
        traits = iPadTraits
      }
    }
    return .init(
      safeArea: .init(top: 20, left: 0, bottom: 0, right: 0),
      size: size,
      traits: traits
    )
  }

  public static let iPadPro11 = DeviceProfile.iPadPro11(.landscape)

  public static func iPadPro11(_ orientation: Orientation) -> DeviceProfile {
    switch orientation {
    case .landscape:
      return DeviceProfile.iPadPro11(.landscape(splitView: .full))
    case .portrait:
      return DeviceProfile.iPadPro11(.portrait(splitView: .full))
    }
  }

  public static func iPadPro11(_ orientation: TabletOrientation) -> DeviceProfile {
    let size: CGSize
    let traits: TraitMutations
    switch orientation {
    case .landscape(let splitView):
      switch splitView {
      case .oneThird:
        size = .init(width: 375, height: 834)
        traits = iPadCompactSplitViewTraits
      case .oneHalf:
        size = .init(width: 592, height: 834)
        traits = iPadCompactSplitViewTraits
      case .twoThirds:
        size = .init(width: 809, height: 834)
        traits = iPadTraits
      case .full:
        size = .init(width: 1194, height: 834)
        traits = iPadTraits
      }
    case .portrait(let splitView):
      switch splitView {
      case .oneThird:
        size = .init(width: 320, height: 1194)
        traits = iPadCompactSplitViewTraits
      case .twoThirds:
        size = .init(width: 504, height: 1194)
        traits = iPadCompactSplitViewTraits
      case .full:
        size = .init(width: 834, height: 1194)
        traits = iPadTraits
      }
    }
    return .init(
      safeArea: .init(top: 24, left: 0, bottom: 20, right: 0),
      size: size,
      traits: traits
    )
  }

  public static let iPadPro12_9 = DeviceProfile.iPadPro12_9(.landscape)

  public static func iPadPro12_9(_ orientation: Orientation) -> DeviceProfile {
    switch orientation {
    case .landscape:
      return DeviceProfile.iPadPro12_9(.landscape(splitView: .full))
    case .portrait:
      return DeviceProfile.iPadPro12_9(.portrait(splitView: .full))
    }
  }

  public static func iPadPro12_9(_ orientation: TabletOrientation) -> DeviceProfile {
    let size: CGSize
    let traits: TraitMutations
    switch orientation {
    case .landscape(let splitView):
      switch splitView {
      case .oneThird:
        size = .init(width: 375, height: 1024)
        traits = iPadCompactSplitViewTraits
      case .oneHalf:
        size = .init(width: 678, height: 1024)
        traits = iPadTraits
      case .twoThirds:
        size = .init(width: 981, height: 1024)
        traits = iPadTraits
      case .full:
        size = .init(width: 1366, height: 1024)
        traits = iPadTraits
      }

    case .portrait(let splitView):
      switch splitView {
      case .oneThird:
        size = .init(width: 375, height: 1366)
        traits = iPadCompactSplitViewTraits
      case .twoThirds:
        size = .init(width: 639, height: 1366)
        traits = iPadCompactSplitViewTraits
      case .full:
        size = .init(width: 1024, height: 1366)
        traits = iPadTraits
      }

    }
    return .init(
      safeArea: .init(top: 20, left: 0, bottom: 0, right: 0),
      size: size,
      traits: traits
    )
  }
  #elseif os(tvOS)
  public static let tv = DeviceProfile(
    safeArea: .init(top: 60, left: 90, bottom: 60, right: 90),
    size: .init(width: 1920, height: 1080)
  )
  public static let tv4K = DeviceProfile(
    safeArea: .init(top: 120, left: 180, bottom: 120, right: 180),
    size: .init(width: 3840, height: 2160)
  )
  #endif
}
#endif
