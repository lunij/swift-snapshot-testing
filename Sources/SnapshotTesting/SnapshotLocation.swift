import Foundation
import Synchronization
import Testing

/// The on-disk locations a snapshot assertion reads from and writes to.
///
/// Deriving these paths from the source location of the calling test is test-harness policy, so it
/// lives here rather than in the snapshot engine.
///
/// A reference is named after the test that took it, what the strategy renders, and whatever the
/// author added to tell two snapshots of one test apart. That name is then looked for at three rungs,
/// most specific first:
///
/// ```
/// <stem>.macos26.png
/// <stem>.macos.png
/// <stem>.png
/// ```
///
/// The most specific rung that exists wins, and a snapshot with no reference yet records the last.
/// Nothing parses an existing file name — the three candidates are built here and probed — so a
/// suffix that happens to read like a platform is never mistaken for one.
///
/// The upshot is that platform-independent output keeps one shared reference indefinitely, while a
/// value that renders differently per platform is split apart by moving the file once. Which rung is
/// in use never depends on when an assertion runs, only on what is on disk, so a name resolves the
/// same on a recording run as on a verifying one.
struct SnapshotLocation {
  /// The reference snapshot file.
  let snapshotURL: URL

  /// The directory failure artifacts are written to.
  let artifactDirectory: URL

  /// The file this platform would record under, or `nil` when ``snapshotURL`` already names a
  /// platform.
  ///
  /// Non-`nil` means the reference is shared by every platform, which is worth saying out loud when
  /// it turns out not to match.
  let platformSpecificName: String?

  /// Whether an earlier snapshot in this test already resolved to ``snapshotURL`` while deriving its
  /// whole name.
  ///
  /// A snapshot given a suffix is left alone: naming a file explicitly says the author meant that
  /// file, and a test that snapshots the same reference twice over — to watch it be recorded and then
  /// matched — depends on being able to.
  let isDuplicate: Bool

  /// Derives the locations of a single snapshot.
  ///
  /// - Parameters:
  ///   - identifier: What the strategy renders, when its path extension does not already say.
  ///   - suffix: An optional suffix distinguishing several snapshots taken by the same test.
  ///   - pathExtension: The path extension of the strategy's format, if any.
  ///   - snapshotDirectory: An optional override for the directory holding reference snapshots. By
  ///     default snapshots are saved in a directory with the same name as the test file, inside a
  ///     `__Snapshots__` directory that sits next to the test file.
  ///   - filePath: The file the assertion was made in.
  ///   - testName: The function the assertion was made in.
  init(
    identifier: String?,
    suffixed suffix: String?,
    pathExtension: String?,
    snapshotDirectory: String?,
    filePath: StaticString,
    testName: String
  ) {
    let fileURL = URL(filePath: "\(filePath)")
    let fileName = fileURL.deletingPathExtension().lastPathComponent

    let testFileDirectoryURL = fileURL.deletingLastPathComponent()
    let snapshotDirectoryURL =
      snapshotDirectory.map { URL(filePath: $0, directoryHint: .isDirectory) }
      ?? testFileDirectoryURL.appending(path: "__Snapshots__").appending(path: fileName)

    var stem = sanitizePathComponent(testName)
    if let identifier {
      stem += ".\(sanitizePathComponent(identifier))"
    }
    if let suffix {
      stem += ".\(sanitizePathComponent(suffix))"
    }

    func url(qualifiedBy platform: String?) -> URL {
      var url = snapshotDirectoryURL.appending(path: platform.map { "\(stem).\($0)" } ?? stem)
      if let pathExtension {
        url = url.appendingPathExtension(pathExtension)
      }
      return url
    }

    let sharedURL = url(qualifiedBy: nil)
    let platformURL = url(qualifiedBy: SnapshotPlatform.name)
    let versionedURL = url(qualifiedBy: SnapshotPlatform.versionedName)

    let fileManager = FileManager.default
    let snapshotURL =
      [versionedURL, platformURL].first { fileManager.fileExists(atPath: $0.path) } ?? sharedURL

    let artifactsBaseURL = URL(
      filePath: ProcessInfo.processInfo.environment["SNAPSHOT_ARTIFACTS"]
        ?? NSTemporaryDirectory(),
      directoryHint: .isDirectory
    )

    self.snapshotURL = snapshotURL
    self.artifactDirectory = artifactsBaseURL.appending(path: fileName)
    self.platformSpecificName =
      snapshotURL == sharedURL && platformURL != sharedURL
      ? platformURL.lastPathComponent
      : nil
    self.isDuplicate = register.claim(snapshotURL) && suffix == nil
  }
}

// MARK: - Private

private var register: Register { Register.current }

private func sanitizePathComponent(_ string: String) -> String {
  string
    .replacingOccurrences(of: "\\W+", with: "-", options: .regularExpression)
    .replacingOccurrences(of: "^-|-$", with: "", options: .regularExpression)
}

/// The reference files a test has already resolved.
///
/// Two snapshots of one test that derive the same name would otherwise share a reference, each
/// overwriting what the other recorded. The register is what lets that be reported instead. Every
/// resolution is claimed, so that a derived name colliding with an explicitly suffixed one is caught
/// as well.
final class Register: Sendable {
  @TaskLocal static var current = Register()

  private let claimed = Mutex<Set<URL>>([])

  init() {}

  /// Claims `url` for the current test, returning whether it had already been claimed.
  func claim(_ url: URL) -> Bool {
    claimed.withLock { !$0.insert(url).inserted }
  }
}
