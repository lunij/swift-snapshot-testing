import Foundation

/// Compares two snapshot format values and produces a failure description when they differ.
public struct SnapshotComparator<Value> {
  /// Compares two values. If the values do not match, returns a failure describing the mismatch.
  public var diff: (Value, Value) throws -> SnapshotFailure?

  public init(diff: @escaping (_ lhs: Value, _ rhs: Value) throws -> SnapshotFailure?) {
    self.diff = diff
  }
}
