import Foundation

/// A type representing the ability to transform a snapshottable value into a diffable format (like
/// text or an image) for snapshotting.
public struct SnapshotStrategy<Value, Format> {
  /// The path extension applied to references saved to disk.
  public var pathExtension: String?

  /// Serializes and deserializes the snapshot format to and from `Data` for disk storage.
  public var serializer: SnapshotSerializer<Format>

  /// Compares two snapshot format values and produces a failure description when they differ.
  public var comparator: SnapshotComparator<Format>

  /// How a value is transformed into a diffable snapshot format.
  ///
  /// The closure is `nonisolated(nonsending)`: it runs on the caller's actor, so non-Sendable
  /// values never cross an isolation boundary on their way into a snapshot strategy.
  public var snapshot: nonisolated(nonsending) (Value) async -> Format

  /// Creates a snapshot strategy.
  ///
  /// - Parameters:
  ///   - pathExtension: The path extension applied to references saved to disk.
  ///   - serializer: How to serialize and deserialize the snapshot format to and from `Data`.
  ///   - comparator: How to compare two snapshot format values.
  ///   - snapshot: A transform function from a value into a diffable snapshot format.
  ///     Synchronous closures are accepted because non-async is a subtype of async in Swift.
  public init(
    pathExtension: String?,
    serializer: SnapshotSerializer<Format>,
    comparator: SnapshotComparator<Format>,
    snapshot: nonisolated(nonsending) @escaping (_ value: Value) async -> Format
  ) {
    self.pathExtension = pathExtension
    self.serializer = serializer
    self.comparator = comparator
    self.snapshot = snapshot
  }

  /// Transforms a strategy on `Value`s into a strategy on `NewValue`s through a function
  /// `(NewValue) -> Value`.
  ///
  /// This is the most important operation for transforming existing strategies into new strategies.
  /// It allows you to transform a `SnapshotStrategy<Value, Format>` into a
  /// `SnapshotStrategy<NewValue, Format>` by pulling it back along a function `(NewValue) -> Value`.
  /// Notice that the function must go in the direction `(NewValue) -> Value` even though we are
  /// transforming in the other direction
  /// `(SnapshotStrategy<Value, Format>) -> SnapshotStrategy<NewValue, Format>`.
  ///
  /// A simple example of this is to `pullback` the snapshot strategy on `UIView`s to work on
  /// `UIViewController`s:
  ///
  /// ```swift
  /// let strategy = SnapshotStrategy<UIView, UIImage>.image.pullback { (vc: UIViewController) in
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
  ) -> SnapshotStrategy<NewValue, Format> {
    SnapshotStrategy<NewValue, Format>(
      pathExtension: pathExtension,
      serializer: serializer,
      comparator: comparator
    ) { newValue in
      await self.snapshot(transform(newValue))
    }
  }

  /// Transforms this strategy into a strategy on a new value type.
  ///
  /// Most strategies are built this way. Given a strategy that snapshots `UIView`s as `UIImage`s,
  /// a strategy for `UIViewController`s only needs a way to reach the view:
  ///
  /// ```swift
  /// let strategy = SnapshotStrategy<UIView, UIImage>.image
  ///   .transform(to: UIViewController.self) { $0.view }
  /// ```
  ///
  /// Notice that the transform runs in the opposite direction to the strategy: the strategy moves
  /// from `Value` to `NewValue`, while the transform moves from `NewValue` back to `Value`.
  ///
  /// - Parameters:
  ///   - type: The value type of the resulting strategy. It defaults to the generic, so it only
  ///     needs spelling out where the compiler cannot infer it from context.
  ///   - transform: A transform function from the new value into this strategy's value. Synchronous
  ///     closures are accepted because non-async is a subtype of async in Swift.
  public func transform<NewValue>(
    to type: NewValue.Type = NewValue.self,
    _ transform: nonisolated(nonsending) @escaping (_ newValue: NewValue) async -> Value
  ) -> SnapshotStrategy<NewValue, Format> {
    SnapshotStrategy<NewValue, Format>(
      pathExtension: pathExtension,
      serializer: serializer,
      comparator: comparator
    ) { newValue in
      await self.snapshot(await transform(newValue))
    }
  }
}

/// A snapshot strategy where the type being snapshot is also a diffable type.
public typealias DirectSnapshotStrategy<Format> = SnapshotStrategy<Format, Format>

extension SnapshotStrategy where Value == Format {
  public init(
    pathExtension: String?,
    serializer: SnapshotSerializer<Format>,
    comparator: SnapshotComparator<Format>
  ) {
    self.init(
      pathExtension: pathExtension,
      serializer: serializer,
      comparator: comparator,
      snapshot: { $0 }
    )
  }
}
