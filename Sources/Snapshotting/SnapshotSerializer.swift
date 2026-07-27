import Foundation

/// Serializes and deserializes a snapshot format value to and from raw `Data` for disk storage.
public struct SnapshotSerializer<Value> {
  /// Converts a value to data for writing to disk.
  public var toData: (Value) throws -> Data

  /// Produces a value from data read from disk.
  public var fromData: (Data) throws -> Value

  public init(
    toData: @escaping (_ value: Value) throws -> Data,
    fromData: @escaping (_ data: Data) throws -> Value
  ) {
    self.toData = toData
    self.fromData = fromData
  }
}
