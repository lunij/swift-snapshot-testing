import Foundation

extension Snapshotting where Value == String, Format == String {
  /// A snapshot strategy for comparing strings based on equality.
  public static var lines: Snapshotting {
    Snapshotting(pathExtension: "txt", diffing: .lines)
  }
}

extension Diffing where Value == String {
  /// A line-diffing strategy for UTF-8 text.
  public static var lines: Diffing {
    Diffing.diff(
      toData: { Data($0.utf8) },
      fromData: { String(decoding: $0, as: UTF8.self) }
    ) { old, new in
      guard old != new else { return nil }
      let differences = SnapshotTesting.diff(
        old.split(separator: "\n", omittingEmptySubsequences: false).map(String.init),
        new.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
      )
      let removed = differences.filter { $0.which == .first }.reduce(0) { $0 + $1.elements.count }
      let added = differences.filter { $0.which == .second }.reduce(0) { $0 + $1.elements.count }
      let patch =
        chunk(diff: differences)
        .flatMap { [$0.patchMark] + $0.lines }
        .joined(separator: "\n")
      return SnapshotFailure(
        reason: "Text does not match reference (+\(added) −\(removed) lines).",
        detail: patch,
        attachments: [.data(Data(patch.utf8), name: "difference.patch")]
      )
    }
  }
}
