import Foundation
import XCTest

/// The ability to compare `Value`s and convert them to and from `Data`.
public struct Diffing<Value> {
  /// Converts a value _to_ data.
  public var toData: (Value) throws -> Data

  /// Produces a value _from_ data.
  public var fromData: (Data) -> Value

  /// Compares two values. If the values do not match, returns a failure message and artifacts
  /// describing the failure.
  public var diffV2: (Value, Value) throws -> (String, [DiffAttachment])?

  private init(
    toData: @escaping (Value) throws -> Data,
    fromData: @escaping (Data) -> Value,
    diffV2: @escaping (Value, Value) throws -> (String, [DiffAttachment])?
  ) {
    self.toData = toData
    self.fromData = fromData
    self.diffV2 = diffV2
  }

  public static func diff(
    toData: @escaping (_ value: Value) throws -> Data,
    fromData: @escaping (_ data: Data) -> Value,
    diffV2: @escaping (_ lhs: Value, _ rhs: Value) throws -> (String, [DiffAttachment])?
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
