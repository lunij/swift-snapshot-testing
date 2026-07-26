import Foundation

extension Snapshotting where Value == Data, Format == Data {
  /// A snapshot strategy for comparing bare binary data.
  public static var data: Snapshotting {
    return .init(
      pathExtension: nil,
      diffing: .diff(toData: { $0 }, fromData: { $0 }) { old, new in
        guard old != new else { return nil }
        let reason =
          old.count == new.count
          ? "Data does not match reference (\(new.count) bytes)."
          : "Data size \(new.count) bytes does not match reference size \(old.count) bytes."
        return SnapshotFailure(reason: reason)
      }
    )
  }
}
