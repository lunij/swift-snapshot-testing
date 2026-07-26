import Foundation

extension Snapshotting {
  /// Transforms an existing snapshot strategy into one that waits for some amount of time before
  /// taking the snapshot. This can be useful for waiting for animations to complete or for UIKit
  /// events to finish (_i.e._ waiting for a `UINavigationController` to push a child onto the
  /// stack).
  ///
  /// - Parameters:
  ///   - duration: The amount of time to wait before taking the snapshot.
  ///   - strategy: The snapshot to invoke after the specified amount of time has passed.
  public static func wait(
    for duration: TimeInterval,
    on strategy: Self
  ) -> Self {
    Self(
      pathExtension: strategy.pathExtension,
      serializer: strategy.serializer,
      comparator: strategy.comparator
    ) { value in
      try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
      return await strategy.snapshot(value)
    }
  }
}
