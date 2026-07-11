#if os(iOS) || os(tvOS)
import UIKit

extension ViewImageConfig {
#if os(iOS)
    public static func iPhoneSeTraits(_ orientation: Orientation) -> TraitMutations {
        { traits in
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

    public static func iPhone8Traits(_ orientation: Orientation) -> TraitMutations {
        { traits in
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

    public static func iPhone8PlusTraits(_ orientation: Orientation) -> TraitMutations {
        { traits in
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

    public static func iPhoneXTraits(_ orientation: Orientation) -> TraitMutations {
        { traits in
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

    public static func iPhoneXrTraits(_ orientation: Orientation) -> TraitMutations {
        { traits in
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

    public static func iPhoneXsMaxTraits(_ orientation: Orientation) -> TraitMutations {
        { traits in
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

    public static func iPhone12Traits(_ orientation: Orientation) -> TraitMutations {
        { traits in
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

    public static func iPhone12ProMaxTraits(_ orientation: Orientation) -> TraitMutations {
        { traits in
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

    public static func iPhone13Traits(_ orientation: Orientation) -> TraitMutations {
        { traits in
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

    public static func iPhone13ProMaxTraits(_ orientation: Orientation) -> TraitMutations {
        { traits in
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

    public static let iPadTraits: TraitMutations = { traits in
        traits.horizontalSizeClass = .regular
        traits.verticalSizeClass = .regular
        traits.userInterfaceIdiom = .pad
    }

    public static let iPadCompactSplitViewTraits: TraitMutations = { traits in
        traits.horizontalSizeClass = .compact
        traits.verticalSizeClass = .regular
        traits.userInterfaceIdiom = .pad
    }
#endif
}
#endif
