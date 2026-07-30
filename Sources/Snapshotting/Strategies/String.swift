import Foundation

extension SnapshotStrategy where Value == String, Format == String {
  /// A snapshot strategy for comparing strings based on equality.
  public static var lines: SnapshotStrategy {
    SnapshotStrategy(pathExtension: "txt", serializer: .lines, comparator: .lines)
  }
}

extension SnapshotSerializer where Value == String {
  /// A UTF-8 text serializer.
  public static var lines: SnapshotSerializer {
    SnapshotSerializer(
      toData: { Data($0.utf8) },
      fromData: { String(decoding: $0, as: UTF8.self) }
    )
  }
}

extension SnapshotComparator where Value == String {
  /// A line-diffing comparator for UTF-8 text.
  public static var lines: SnapshotComparator {
    SnapshotComparator { old, new in
      guard old != new else { return nil }
      let runs = lineDiff(
        old.split(separator: "\n", omittingEmptySubsequences: false).map(String.init),
        new.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
      )
      let removed = runs.filter { $0.kind == .removed }.reduce(0) { $0 + $1.lines.count }
      let added = runs.filter { $0.kind == .added }.reduce(0) { $0 + $1.lines.count }
      let patch =
        hunks(of: runs)
        .flatMap { [$0.patchMark] + $0.patchLines }
        .joined(separator: "\n")
      return SnapshotFailure(
        reason: "Text does not match reference (+\(added) −\(removed) lines).",
        detail: patch,
        artifacts: [.init(name: "difference.patch", data: Data(patch.utf8))]
      )
    }
  }
}
