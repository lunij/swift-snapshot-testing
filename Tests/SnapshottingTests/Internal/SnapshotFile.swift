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
  init(_ name: String, filePath: StaticString = #filePath) {
    let fileURL = URL(fileURLWithPath: "\(filePath)", isDirectory: false)
    let fileName = fileURL.deletingPathExtension().lastPathComponent

    self.snapshotURL =
      fileURL
      .deletingLastPathComponent()
      .appendingPathComponent("__Snapshots__")
      .appendingPathComponent(fileName)
      .appendingPathComponent(name)
    self.artifactDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
      .appendingPathComponent(fileName)
  }
}
