import Foundation
import XCTest

/// A failure produced by a ``Diffing`` strategy when two values do not match.
public struct SnapshotFailure {
  /// A short, single-sentence description of what specifically failed.
  ///
  /// This becomes the first line of the test failure message, which is the only line visible in
  /// Xcode's issue navigator and inline test failure banner. It should state the concrete reason
  /// (e.g. a size mismatch or precision shortfall), not a generic "snapshot failed".
  public var reason: String

  /// Optional multi-line detail describing the failure, such as a text diff or a precision
  /// breakdown. Rendered below the reason in the failure message.
  public var detail: String?

  /// Artifacts describing the failure, attached to the test report.
  public var attachments: [DiffAttachment]

  init(reason: String, detail: String? = nil, attachments: [DiffAttachment] = []) {
    self.reason = reason
    self.detail = detail
    self.attachments = attachments
  }
}

/// The ability to compare `Value`s and convert them to and from `Data`.
public struct Diffing<Value> {
  /// Converts a value _to_ data.
  public var toData: (Value) throws -> Data

  /// Produces a value _from_ data.
  public var fromData: (Data) throws -> Value

  /// Compares two values. If the values do not match, returns a failure describing the mismatch.
  public var diffV2: (Value, Value) throws -> SnapshotFailure?

  private init(
    toData: @escaping (Value) throws -> Data,
    fromData: @escaping (Data) throws -> Value,
    diffV2: @escaping (Value, Value) throws -> SnapshotFailure?
  ) {
    self.toData = toData
    self.fromData = fromData
    self.diffV2 = diffV2
  }

  public static func diff(
    toData: @escaping (_ value: Value) throws -> Data,
    fromData: @escaping (_ data: Data) throws -> Value,
    diffV2: @escaping (_ lhs: Value, _ rhs: Value) throws -> SnapshotFailure?
  ) -> Self {
    Diffing(toData: toData, fromData: fromData, diffV2: diffV2)
  }
}

public enum DiffAttachment {
  case data(Data, name: String)
}

#if os(iOS) || os(macOS) || os(tvOS) || os(visionOS)
  extension Diffing where Value == XImage {
    static func attachments(
      _ old: Value,
      _ new: Value,
      _ toDiffImage: @escaping (Value, Value) -> Value,
      _ toData: (Value) throws -> Data
    ) throws -> [DiffAttachment] {
      let diff = toDiffImage(old, new)
      return [
        DiffAttachment.data(try toData(old), name: "old"),
        DiffAttachment.data(try toData(new), name: "new"),
        DiffAttachment.data(try toData(diff), name: "diff")
      ]
    }
  }
#endif
