#if os(iOS) || os(tvOS)
import UIKit

/// A closure that mutates a set of UI traits.
///
/// The `Sendable` counterpart of `UITraitCollection.TraitMutations`.
public typealias TraitMutations = @Sendable (inout any UIMutableTraits) -> Void
#endif
