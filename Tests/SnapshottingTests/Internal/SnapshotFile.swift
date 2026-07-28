import Foundation

/// The reference snapshot a test compares against, and where a mismatch is written.
///
/// Reference files are named explicitly. There is no per-test counter, so a value snapshot twice in
/// one test needs two names.
struct SnapshotFile {
  /// The reference file, inside `__Snapshots__/<file name>/` next to the calling file.
  let snapshotURL: URL

  /// The directory a mismatching snapshot is written to, so that it can be diffed.
  let artifactDirectory: URL

  /// - Parameters:
  ///   - name: The reference file's name, including its path extension.
  ///   - filePath: The file requesting the snapshot.
  init(_ name: String, filePath: String) {
    let fileURL = URL(filePath: filePath, directoryHint: .isDirectory)
    let fileName = fileURL.deletingPathExtension().lastPathComponent

    self.snapshotURL =
      fileURL
      .deletingLastPathComponent()
      .appending(path: "__Snapshots__")
      .appending(path: fileName)
      .appending(path: name)
    self.artifactDirectory = URL(filePath: NSTemporaryDirectory(), directoryHint: .isDirectory)
      .appending(path: fileName)
  }
}
