#if os(iOS) || os(tvOS)
import UIKit

extension UITraitCollection {
#if os(iOS)
    public static func iPhoneSe(_ orientation: ViewImageConfig.Orientation) -> UITraitCollection {
        UITraitCollection { traits in
            traits.forceTouchCapability = .available
            traits.layoutDirection = .leftToRight
            traits.preferredContentSizeCategory = .medium
            traits.userInterfaceIdiom = .phone
            switch orientation {
            case .landscape:
                traits.horizontalSizeClass = .compact
                traits.verticalSizeClass = .compact
            case .portrait:
                traits.horizontalSizeClass = .compact
                traits.verticalSizeClass = .regular
            }
        }
    }

    public static func iPhone8(_ orientation: ViewImageConfig.Orientation) -> UITraitCollection {
        UITraitCollection { traits in
            traits.forceTouchCapability = .available
            traits.layoutDirection = .leftToRight
            traits.preferredContentSizeCategory = .medium
            traits.userInterfaceIdiom = .phone
            switch orientation {
            case .landscape:
                traits.horizontalSizeClass = .compact
                traits.verticalSizeClass = .compact
            case .portrait:
                traits.horizontalSizeClass = .compact
                traits.verticalSizeClass = .regular
            }
        }
    }

    public static func iPhone8Plus(_ orientation: ViewImageConfig.Orientation) -> UITraitCollection {
        UITraitCollection { traits in
            traits.forceTouchCapability = .available
            traits.layoutDirection = .leftToRight
            traits.preferredContentSizeCategory = .medium
            traits.userInterfaceIdiom = .phone
            switch orientation {
            case .landscape:
                traits.horizontalSizeClass = .regular
                traits.verticalSizeClass = .compact
            case .portrait:
                traits.horizontalSizeClass = .compact
                traits.verticalSizeClass = .regular
            }
        }
    }

    public static func iPhoneX(_ orientation: ViewImageConfig.Orientation) -> UITraitCollection {
        UITraitCollection { traits in
            traits.forceTouchCapability = .available
            traits.layoutDirection = .leftToRight
            traits.preferredContentSizeCategory = .medium
            traits.userInterfaceIdiom = .phone
            switch orientation {
            case .landscape:
                traits.horizontalSizeClass = .compact
                traits.verticalSizeClass = .compact
            case .portrait:
                traits.horizontalSizeClass = .compact
                traits.verticalSizeClass = .regular
            }
        }
    }

    public static func iPhoneXr(_ orientation: ViewImageConfig.Orientation) -> UITraitCollection {
        UITraitCollection { traits in
            traits.forceTouchCapability = .unavailable
            traits.layoutDirection = .leftToRight
            traits.preferredContentSizeCategory = .medium
            traits.userInterfaceIdiom = .phone
            switch orientation {
            case .landscape:
                traits.horizontalSizeClass = .regular
                traits.verticalSizeClass = .compact
            case .portrait:
                traits.horizontalSizeClass = .compact
                traits.verticalSizeClass = .regular
            }
        }
    }

    public static func iPhoneXsMax(_ orientation: ViewImageConfig.Orientation) -> UITraitCollection {
        UITraitCollection { traits in
            traits.forceTouchCapability = .available
            traits.layoutDirection = .leftToRight
            traits.preferredContentSizeCategory = .medium
            traits.userInterfaceIdiom = .phone
            switch orientation {
            case .landscape:
                traits.horizontalSizeClass = .regular
                traits.verticalSizeClass = .compact
            case .portrait:
                traits.horizontalSizeClass = .compact
                traits.verticalSizeClass = .regular
            }
        }
    }

    public static func iPhone12(_ orientation: ViewImageConfig.Orientation) -> UITraitCollection {
        UITraitCollection { traits in
            traits.forceTouchCapability = .available
            traits.layoutDirection = .leftToRight
            traits.preferredContentSizeCategory = .medium
            traits.userInterfaceIdiom = .phone
            switch orientation {
            case .landscape:
                traits.horizontalSizeClass = .compact
                traits.verticalSizeClass = .compact
            case .portrait:
                traits.horizontalSizeClass = .compact
                traits.verticalSizeClass = .regular
            }
        }
    }

    public static func iPhone12ProMax(_ orientation: ViewImageConfig.Orientation) -> UITraitCollection {
        UITraitCollection { traits in
            traits.forceTouchCapability = .available
            traits.layoutDirection = .leftToRight
            traits.preferredContentSizeCategory = .medium
            traits.userInterfaceIdiom = .phone
            switch orientation {
            case .landscape:
                traits.horizontalSizeClass = .regular
                traits.verticalSizeClass = .compact
            case .portrait:
                traits.horizontalSizeClass = .compact
                traits.verticalSizeClass = .regular
            }
        }
    }

    public static func iPhone13(_ orientation: ViewImageConfig.Orientation) -> UITraitCollection {
        UITraitCollection { traits in
            traits.forceTouchCapability = .available
            traits.layoutDirection = .leftToRight
            traits.preferredContentSizeCategory = .medium
            traits.userInterfaceIdiom = .phone
            switch orientation {
            case .landscape:
                traits.horizontalSizeClass = .compact
                traits.verticalSizeClass = .compact
            case .portrait:
                traits.horizontalSizeClass = .compact
                traits.verticalSizeClass = .regular
            }
        }
    }

    public static func iPhone13ProMax(_ orientation: ViewImageConfig.Orientation) -> UITraitCollection {
        UITraitCollection { traits in
            traits.forceTouchCapability = .available
            traits.layoutDirection = .leftToRight
            traits.preferredContentSizeCategory = .medium
            traits.userInterfaceIdiom = .phone
            switch orientation {
            case .landscape:
                traits.horizontalSizeClass = .regular
                traits.verticalSizeClass = .compact
            case .portrait:
                traits.horizontalSizeClass = .compact
                traits.verticalSizeClass = .regular
            }
        }
    }

    public static let iPadMini = iPad
    public static let iPadMini_Compact_SplitView = iPadCompactSplitView
    public static let iPad9_7 = iPad
    public static let iPad9_7_Compact_SplitView = iPadCompactSplitView
    public static let iPad10_2 = iPad
    public static let iPad10_2_Compact_SplitView = iPadCompactSplitView
    public static let iPadPro10_5 = iPad
    public static let iPadPro10_5_Compact_SplitView = iPadCompactSplitView
    public static let iPadPro11 = iPad
    public static let iPadPro11_Compact_SplitView = iPadCompactSplitView
    public static let iPadPro12_9 = iPad
    public static let iPadPro12_9_Compact_SplitView = iPadCompactSplitView

    private static let iPad = UITraitCollection { mutableTraits in
        mutableTraits.horizontalSizeClass = .regular
        mutableTraits.verticalSizeClass = .regular
        mutableTraits.userInterfaceIdiom = .pad
    }

    private static let iPadCompactSplitView = UITraitCollection { mutableTraits in
        mutableTraits.horizontalSizeClass = .compact
        mutableTraits.verticalSizeClass = .regular
        mutableTraits.userInterfaceIdiom = .pad
    }
#elseif os(tvOS)
    // TODO
#endif
}
#endif
