import Foundation

/// A failure produced by a ``Diffing`` strategy when two values do not match.
public struct SnapshotFailure: Sendable {
  /// A short, single-sentence description of what specifically failed.
  ///
  /// This becomes the first line of the test failure message, which is the only line visible in
  /// Xcode's issue navigator and inline test failure banner. It should state the concrete reason
  /// (e.g. a size mismatch or precision shortfall), not a generic "snapshot failed".
  public let reason: String

  /// Optional multi-line detail describing the failure, such as a text diff or a precision
  /// breakdown. Rendered below the reason in the failure message.
  public let detail: String?

  /// Artifacts describing the failure.
  public let artifacts: [Artifact]

  public init(reason: String, detail: String? = nil, artifacts: [Artifact] = []) {
    self.reason = reason
    self.detail = detail
    self.artifacts = artifacts
  }

  public struct Artifact: Sendable {
    public let name: String
    public let data: Data
  }
}

/// The ability to compare `Value`s and convert them to and from `Data`.
public struct Diffing<Value> {
  /// Converts a value _to_ data.
  public var toData: (Value) throws -> Data

  /// Produces a value _from_ data.
  public var fromData: (Data) throws -> Value

  /// Compares two values. If the values do not match, returns a failure describing the mismatch.
  public var diff: (Value, Value) throws -> SnapshotFailure?

  private init(
    toData: @escaping (Value) throws -> Data,
    fromData: @escaping (Data) throws -> Value,
    diff: @escaping (Value, Value) throws -> SnapshotFailure?
  ) {
    self.toData = toData
    self.fromData = fromData
    self.diff = diff
  }

  public static func diff(
    toData: @escaping (_ value: Value) throws -> Data,
    fromData: @escaping (_ data: Data) throws -> Value,
    diff: @escaping (_ lhs: Value, _ rhs: Value) throws -> SnapshotFailure?
  ) -> Self {
    Diffing(toData: toData, fromData: fromData, diff: diff)
  }
}

#if os(iOS) || os(macOS) || os(tvOS) || os(visionOS)
extension Diffing where Value == XImage {
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
