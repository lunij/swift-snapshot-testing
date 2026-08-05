#if os(iOS) || os(macOS) || os(tvOS) || os(visionOS)
import Foundation

extension SnapshotComparator where Value == XImage {
  /// The images worth surfacing alongside a mismatch: the two that were compared, and a diff of
  /// them. The diff is omitted rather than substituted when it cannot be produced, so that a
  /// mismatch is still reported when only the visualization of it fails.
  static func artifacts(
    _ old: Value,
    _ new: Value,
    _ toDiffImage: (Value, Value) -> Value?,
    _ toData: (Value) throws -> Data
  ) throws -> [SnapshotArtifact] {
    var artifacts: [SnapshotArtifact] = [
      .init(name: "old.png", data: try toData(old)),
      .init(name: "new.png", data: try toData(new))
    ]
    if let diff = toDiffImage(old, new) {
      artifacts.append(.init(name: "diff.png", data: try toData(diff)))
    }
    return artifacts
  }
}
#endif
