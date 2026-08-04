import Foundation

/// A type representing the ability to transform a snapshottable value into a diffable format (like
/// text or an image) for snapshotting.
public struct SnapshotStrategy<Value, Format> {
  /// An identifier to be conditionally added to the filename to distinguish recordings.
  public let identifier: String?

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
  public var snapshot: nonisolated(nonsending) (Value) async throws -> Format

  /// Creates a snapshot strategy.
  ///
  /// - Parameters:
  ///   - identifier: An identifier to be conditionally added to the filename to distinguish recordings.
  ///   - pathExtension: The path extension applied to references saved to disk.
  ///   - serializer: How to serialize and deserialize the snapshot format to and from `Data`.
  ///   - comparator: How to compare two snapshot format values.
  ///   - snapshot: A transform function from a value into a diffable snapshot format.
  ///     Synchronous closures are accepted because non-async is a subtype of async in Swift.
  public init(
    identifier: String? = nil,
    pathExtension: String?,
    serializer: SnapshotSerializer<Format>,
    comparator: SnapshotComparator<Format>,
    snapshot: nonisolated(nonsending) @escaping (_ value: Value) async throws -> Format
  ) {
    self.identifier = identifier
    self.pathExtension = pathExtension
    self.serializer = serializer
    self.comparator = comparator
    self.snapshot = snapshot
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
  ///   - identifier: The new identifier or `nil` to take current identifier over to the resulting strategy.
  ///   - transform: A transform function from the new value into this strategy's value. Synchronous
  ///     closures are accepted because non-async is a subtype of async in Swift.
  public func transform<NewValue>(
    to type: NewValue.Type = NewValue.self,
    identifier: String? = nil,
    _ transform: @escaping (_ otherValue: NewValue) throws -> Value
  ) -> SnapshotStrategy<NewValue, Format> {
    SnapshotStrategy<NewValue, Format>(
      identifier: identifier ?? self.identifier,
      pathExtension: pathExtension,
      serializer: serializer,
      comparator: comparator
    ) { newValue in
      try await self.snapshot(transform(newValue))
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
  ///   - identifier: The new identifier or `nil` to take current identifier over to the resulting strategy.
  ///   - transform: A transform function from the new value into this strategy's value. Synchronous
  ///     closures are accepted because non-async is a subtype of async in Swift.
  public func transform<NewValue>(
    to type: NewValue.Type = NewValue.self,
    identifier: String? = nil,
    _ transform: nonisolated(nonsending) @escaping (_ newValue: NewValue) async throws -> Value
  ) -> SnapshotStrategy<NewValue, Format> {
    SnapshotStrategy<NewValue, Format>(
      identifier: identifier ?? self.identifier,
      pathExtension: pathExtension,
      serializer: serializer,
      comparator: comparator
    ) { newValue in
      try await self.snapshot(await transform(newValue))
    }
  }
}

/// A snapshot strategy where the type being snapshot is also a diffable type.
public typealias DirectSnapshotStrategy<Format> = SnapshotStrategy<Format, Format>

extension SnapshotStrategy where Value == Format {
  public init(
    identifier: String? = nil,
    pathExtension: String?,
    serializer: SnapshotSerializer<Format>,
    comparator: SnapshotComparator<Format>
  ) {
    self.init(
      identifier: identifier,
      pathExtension: pathExtension,
      serializer: serializer,
      comparator: comparator,
      snapshot: { $0 }
    )
  }
}
