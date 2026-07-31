#if os(iOS) || os(macOS) || os(tvOS) || os(visionOS)
import Foundation

extension SnapshotComparator where Value == XImage {
  static func artifacts(
    _ old: Value,
    _ new: Value,
    _ toDiffImage: @escaping (Value, Value) -> Value,
    _ toData: (Value) throws -> Data
  ) throws -> [SnapshotArtifact] {
    let diff = toDiffImage(old, new)
    return [
      .init(name: "old.png", data: try toData(old)),
      .init(name: "new.png", data: try toData(new)),
      .init(name: "diff.png", data: try toData(diff))
    ]
  }
}
#endif
