import Foundation

/// The reference snapshot a test compares against, and where a mismatch is written.
///
/// A reference is looked for at three names, most specific first — `<stem>.macos26.png`,
/// `<stem>.macos.png`, `<stem>.png` — and the most specific one that exists wins. A snapshot with no
/// reference yet records the last, so output that renders the same everywhere keeps one shared file.
struct SnapshotFile {
  /// The reference file, inside `__Snapshots__/<file name>/` next to the calling file.
  let snapshotURL: URL

  /// The directory a mismatching snapshot is written to, so that it can be diffed.
  let artifactDirectory: URL

  /// - Parameters:
  ///   - stem: The reference file's name, without a path extension and without a platform.
  ///   - pathExtension: The path extension of the strategy's format, if any.
  ///   - filePath: The file requesting the snapshot.
  init(stem: String, pathExtension: String?, filePath: String) {
    let fileURL = URL(filePath: filePath, directoryHint: .isDirectory)
    let fileName = fileURL.deletingPathExtension().lastPathComponent

    let directoryURL =
      fileURL
      .deletingLastPathComponent()
      .appending(path: "__Snapshots__")
      .appending(path: fileName)

    func url(qualifiedBy platform: String?) -> URL {
      var url = directoryURL.appending(path: platform.map { "\(stem).\($0)" } ?? stem)
      if let pathExtension {
        url = url.appendingPathExtension(pathExtension)
      }
      return url
    }

    let fileManager = FileManager.default
    self.snapshotURL =
      [url(qualifiedBy: SnapshotPlatform.versionedName), url(qualifiedBy: SnapshotPlatform.name)]
      .first { fileManager.fileExists(atPath: $0.path) } ?? url(qualifiedBy: nil)
    self.artifactDirectory = URL(filePath: NSTemporaryDirectory(), directoryHint: .isDirectory)
      .appending(path: fileName)
  }
}
