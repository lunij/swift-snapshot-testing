import Foundation
import Testing

/// The on-disk locations a snapshot assertion reads from and writes to.
///
/// Deriving these paths from the source location of the calling test is test-harness policy, so it
/// lives here rather than in the snapshot engine.
///
/// A snapshot is identified by the name it was given, or by a number when it was given none. Both
/// come from the test's ``Register``: a name claims the file it resolves to, a number counts how
/// often the test has taken an unnamed snapshot.
struct SnapshotLocation {
  /// The reference snapshot file.
  let snapshotURL: URL

  /// The directory failure artifacts are written to.
  let artifactDirectory: URL

  /// The name of the test, sanitized for use as a path component.
  let testName: String

  /// Why the snapshot must not be taken, or `nil` when there is no reason.
  ///
  /// A location that cannot identify a snapshot is worse than no location: it names a file some
  /// other snapshot also writes. Saying so is left to the caller, which knows where to report it.
  let refusal: String?

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
    let fileURL = URL(filePath: "\(filePath)")
    let fileName = fileURL.deletingPathExtension().lastPathComponent

    let testFileDirectoryURL = fileURL.deletingLastPathComponent()
    let snapshotDirectoryURL =
      snapshotDirectory.map { URL(filePath: $0, directoryHint: .isDirectory) }
      ?? testFileDirectoryURL.appending(path: "__Snapshots__").appending(path: fileName)

    let register = Register.current
    let sanitizedTestName = sanitizePathComponent(testName)

    var stem = sanitizedTestName
    var refusal: String?
    if let name {
      stem += ".\(sanitizePathComponent(name))"
    } else if Test.Case.current?.isParameterized == true {
      // The cases of a parameterized test share a name and run in parallel, so the number a case
      // draws is the order it happened to run in, and it stands for a different argument on the next
      // run. Nothing here can tell the arguments apart — the testing library does not publish them —
      // so the only honest number is none.
      refusal = """
        A parameterized test cannot number its snapshots, because its cases run in parallel and a \
        number would stand for a different argument on every run. Name this snapshot after the \
        argument it was taken from.
        """
    } else {
      stem += ".\(register.claim(snapshotDirectoryURL.appending(path: testName).absoluteString))"
    }

    var snapshotURL = snapshotDirectoryURL.appending(path: stem)
    if let pathExtension {
      snapshotURL = snapshotURL.appendingPathExtension(pathExtension)
    }

    // A refused snapshot is not taken, so the claim it would have made is not registered.
    if refusal == nil {
      _ = register.claim(snapshotURL.absoluteString)
    }

    let artifactsBaseURL = URL(
      filePath: ProcessInfo.processInfo.environment["SNAPSHOT_ARTIFACTS"]
        ?? NSTemporaryDirectory(),
      directoryHint: .isDirectory
    )

    self.snapshotURL = snapshotURL
    self.artifactDirectory = artifactsBaseURL.appending(path: fileName)
    self.testName = sanitizedTestName
    self.refusal = refusal
  }
}

// MARK: - Private

private func sanitizePathComponent(_ string: String) -> String {
  string
    .replacingOccurrences(of: "\\W+", with: "-", options: .regularExpression)
    .replacingOccurrences(of: "^-|-$", with: "", options: .regularExpression)
}
