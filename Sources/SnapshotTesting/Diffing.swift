import Foundation
import XCTest

/// The ability to compare `Value`s and convert them to and from `Data`.
public struct Diffing<Value> {
  /// Converts a value _to_ data.
  public var toData: (Value) -> Data

  /// Produces a value _from_ data.
  public var fromData: (Data) -> Value

  /// Compares two values. If the values do not match, returns a failure message and artifacts
  /// describing the failure.
  public var diffV2: (Value, Value) -> (String, [DiffAttachment])?

  private init(
    toData: @escaping (Value) -> Data,
    fromData: @escaping (Data) -> Value,
    diffV2: @escaping (Value, Value) -> (String, [DiffAttachment])?
  ) {
    self.toData = toData
    self.fromData = fromData
    self.diffV2 = diffV2
  }

  public static func diff(
    toData: @escaping (_ value: Value) -> Data,
    fromData: @escaping (_ data: Data) -> Value,
    diffV2: @escaping (_ lhs: Value, _ rhs: Value) -> (String, [DiffAttachment])?
  ) -> Self {
    Diffing(toData: toData, fromData: fromData, diffV2: diffV2)
  }
}

public enum DiffAttachment {
  case data(Data, name: String)
}
