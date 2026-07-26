import Foundation

/// A type representing the ability to transform a snapshottable value into a diffable format (like
/// text or an image) for snapshot testing.
public struct Snapshotting<Value, Format> {
  /// The path extension applied to references saved to disk.
  public var pathExtension: String?

  /// How the snapshot format is diffed and converted to and from data.
  public var diffing: Diffing<Format>

  /// How a value is transformed into a diffable snapshot format.
  ///
  /// The closure is `nonisolated(nonsending)`: it runs on the caller's actor, so non-Sendable
  /// values never cross an isolation boundary on their way into a snapshot strategy.
  public var snapshot: nonisolated(nonsending) (Value) async -> Format

  /// Creates a snapshot strategy.
  ///
  /// - Parameters:
  ///   - pathExtension: The path extension applied to references saved to disk.
  ///   - diffing: How to diff and convert the snapshot format to and from data.
  ///   - snapshot: A transform function from a value into a diffable snapshot format.
  ///     Synchronous closures are accepted because non-async is a subtype of async in Swift.
  public init(
    pathExtension: String?,
    diffing: Diffing<Format>,
    snapshot: nonisolated(nonsending) @escaping (_ value: Value) async -> Format
  ) {
    self.pathExtension = pathExtension
    self.diffing = diffing
    self.snapshot = snapshot
  }

  /// Transforms a strategy on `Value`s into a strategy on `NewValue`s through a function
  /// `(NewValue) -> Value`.
  ///
  /// This is the most important operation for transforming existing strategies into new strategies.
  /// It allows you to transform a `Snapshotting<Value, Format>` into a
  /// `Snapshotting<NewValue, Format>` by pulling it back along a function `(NewValue) -> Value`.
  /// Notice that the function must go in the direction `(NewValue) -> Value` even though we are
  /// transforming in the other direction
  /// `(Snapshotting<Value, Format>) -> Snapshotting<NewValue, Format>`.
  ///
  /// A simple example of this is to `pullback` the snapshot strategy on `UIView`s to work on
  /// `UIViewController`s:
  ///
  /// ```swift
  /// let strategy = Snapshotting<UIView, UIImage>.image.pullback { (vc: UIViewController) in
  ///   vc.view
  /// }
  /// ```
  ///
  /// Here we took the strategy that snapshots `UIView`s as `UIImage`s and pulled it back to work on
  /// `UIViewController`s by using the function `(UIViewController) -> UIView` that simply plucks
  /// the view out of the controller.
  ///
  /// Nearly every snapshot strategy provided in this library is a pullback of some base strategy,
  /// which shows just how important this operation is.
  ///
  /// - Parameters:
  ///   - transform: A transform function from `NewValue` into `Value`.
  public func pullback<NewValue>(
    _ transform: @escaping (_ otherValue: NewValue) -> Value
  ) -> Snapshotting<NewValue, Format> {
    Snapshotting<NewValue, Format>(
      pathExtension: pathExtension,
      diffing: diffing
    ) { newValue in
      await self.snapshot(transform(newValue))
    }
  }

  /// Transforms a strategy on `Value`s into a strategy on `NewValue`s through an async function
  /// `(NewValue) async -> Value`.
  ///
  /// See the documentation of `pullback` for a full description of how pullbacks work. This
  /// operation differs from `pullback` in that it allows you to use an async transformation
  /// `(NewValue) async -> Value`, which is necessary when your transformation needs to perform
  /// some asynchronous work such as accessing `@MainActor`-isolated properties.
  ///
  /// - Parameters:
  ///   - transform: An async transform function from `NewValue` into `Value`.
  public func asyncPullback<NewValue>(
    _ transform: nonisolated(nonsending) @escaping (_ otherValue: NewValue) async -> Value
  ) -> Snapshotting<NewValue, Format> {
    Snapshotting<NewValue, Format>(
      pathExtension: pathExtension,
      diffing: diffing
    ) { newValue in
      await self.snapshot(await transform(newValue))
    }
  }
}

/// A snapshot strategy where the type being snapshot is also a diffable type.
public typealias SimplySnapshotting<Format> = Snapshotting<Format, Format>

extension Snapshotting where Value == Format {
  public init(pathExtension: String?, diffing: Diffing<Format>) {
    self.init(
      pathExtension: pathExtension,
      diffing: diffing,
      snapshot: { $0 }
    )
  }
}
