import Foundation

/// Compares two snapshot format values and produces a failure description when they differ.
public struct SnapshotComparator<Value> {
  /// Compares two values. If the values do not match, returns a failure describing the mismatch.
  public var diff: (Value, Value) throws -> SnapshotFailure?

  public init(diff: @escaping (_ lhs: Value, _ rhs: Value) throws -> SnapshotFailure?) {
    self.diff = diff
  }
}

#if os(iOS) || os(macOS) || os(tvOS) || os(visionOS)
extension SnapshotComparator where Value == XImage {
  static func artifacts(
    _ old: Value,
    _ new: Value,
    _ toDiffImage: @escaping (Value, Value) -> Value,
    _ toData: (Value) throws -> Data
  ) throws -> [SnapshotFailure.Artifact] {
    let diff = toDiffImage(old, new)
    return [
      .init(name: "old", data: try toData(old)),
      .init(name: "new", data: try toData(new)),
      .init(name: "diff", data: try toData(diff))
    ]
  }
}
#endif
