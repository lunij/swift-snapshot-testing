import Foundation
import Snapshotting

/// The reference snapshot a test compares against, and where a mismatch is written.
///
/// This places the directories; `SnapshotReference` names the file within them.
struct SnapshotFile {
  /// The reference file, inside `__Snapshots__/<file name>/` next to the calling file.
  let reference: SnapshotReference

  /// The directory a mismatching snapshot is written to, so that it can be diffed.
  let artifactDirectory: URL

  /// - Parameters:
  ///   - base: What the snapshot is of.
  ///   - qualifiers: What tells this snapshot from the others sharing its base, most general first.
  ///   - pathExtension: The path extension of the strategy's format, if any.
  ///   - filePath: The file requesting the snapshot.
  init(base: String, qualifiers: [String] = [], pathExtension: String? = nil, filePath: String) {
    let fileURL = URL(filePath: filePath, directoryHint: .isDirectory)
    let fileName = fileURL.deletingPathExtension().lastPathComponent
    let directory =
      fileURL
      .deletingLastPathComponent()
      .appending(path: "__Snapshots__")
      .appending(path: fileName)

    self.reference = SnapshotReference(
      base: base,
      qualifiers: qualifiers,
      pathExtension: pathExtension,
      in: directory
    )
    self.artifactDirectory = URL(filePath: NSTemporaryDirectory(), directoryHint: .isDirectory)
      .appending(path: fileName)
  }
}
