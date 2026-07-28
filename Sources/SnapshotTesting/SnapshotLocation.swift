import Foundation
import Synchronization

#if canImport(Testing)
import Testing
#endif

/// The on-disk locations a snapshot assertion reads from and writes to.
///
/// Deriving these paths from the source location of the calling test is test-harness policy, so it
/// lives here rather than in the snapshot engine.
struct SnapshotLocation {
  /// The reference snapshot file.
  let snapshotURL: URL

  /// The directory failure artifacts are written to.
  let artifactDirectory: URL

  /// The name of the test, sanitized for use as a path component.
  let testName: String

  /// Derives the locations of a single snapshot.
  ///
  /// - Parameters:
  ///   - name: An optional description of the snapshot. When `nil`, snapshots are numbered in the
  ///     order they are taken within a test.
  ///   - pathExtension: The path extension of the strategy's format, if any.
  ///   - snapshotDirectory: An optional override for the directory holding reference snapshots. By
  ///     default snapshots are saved in a directory with the same name as the test file, inside a
  ///     `__Snapshots__` directory that sits next to the test file.
  ///   - filePath: The file the assertion was made in.
  ///   - testName: The function the assertion was made in.
  init(
    named name: String?,
    pathExtension: String?,
    snapshotDirectory: String?,
    filePath: StaticString,
    testName: String
  ) {
    let fileURL = URL(fileURLWithPath: "\(filePath)", isDirectory: false)
    let fileName = fileURL.deletingPathExtension().lastPathComponent

    #if os(Android)
    // When running tests on Android, the CI script copies the Tests/SnapshotTestingTests/__Snapshots__ up to the temporary folder
    let snapshotsBaseURL = URL(
      fileURLWithPath: "/data/local/tmp/android-xctest",
      isDirectory: true
    )
    #else
    let snapshotsBaseURL = fileURL.deletingLastPathComponent()
    #endif

    let snapshotDirectoryURL =
      snapshotDirectory.map { URL(fileURLWithPath: $0, isDirectory: true) }
      ?? snapshotsBaseURL.appendingPathComponent("__Snapshots__").appendingPathComponent(fileName)

    let identifier: String
    if let name {
      identifier = sanitizePathComponent(name)
    } else {
      identifier = String(
        counter.next(for: snapshotDirectoryURL.appendingPathComponent(testName).absoluteString)
      )
    }

    let sanitizedTestName = sanitizePathComponent(testName)
    var snapshotURL =
      snapshotDirectoryURL
      .appendingPathComponent("\(sanitizedTestName).\(identifier)")
    if let pathExtension {
      snapshotURL = snapshotURL.appendingPathExtension(pathExtension)
    }

    let artifactsBaseURL = URL(
      fileURLWithPath: ProcessInfo.processInfo.environment["SNAPSHOT_ARTIFACTS"]
        ?? NSTemporaryDirectory(),
      isDirectory: true
    )

    self.snapshotURL = snapshotURL
    self.artifactDirectory = artifactsBaseURL.appendingPathComponent(fileName)
    self.testName = sanitizedTestName
  }
}

// MARK: - Private

private var counter: File.Counter {
  #if canImport(Testing)
  if Test.current != nil {
    return File.counter
  } else {
    return _counter
  }
  #else
  return _counter
  #endif
}

private let _counter = File.Counter()

private func sanitizePathComponent(_ string: String) -> String {
  string
    .replacingOccurrences(of: "\\W+", with: "-", options: .regularExpression)
    .replacingOccurrences(of: "^-|-$", with: "", options: .regularExpression)
}

enum File {
  @TaskLocal static var counter = Counter()

  final class Counter: Sendable {
    private let counts = Mutex<[String: Int]>([:])

    init() {}

    func next(for key: String) -> Int {
      counts.withLock {
        $0[key, default: 0] += 1
        return $0[key]!
      }
    }

    func reset() {
      counts.withLock { $0.removeAll() }
    }
  }
}
