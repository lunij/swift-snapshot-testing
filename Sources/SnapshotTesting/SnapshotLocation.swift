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
///
/// A parameterized test runs the same function once per argument, so a number counted across those
/// runs would stand for a different argument every time. There the argument identifies the snapshot
/// instead, being the one thing that differs between the runs.
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
  ///   - argument: The argument the test is running under, when the caller knows it. Only a
  ///     parameterized test has one, and only there does it take part in the file name. It has to
  ///     describe itself losslessly, because a description that two arguments share names one file
  ///     they both write.
  ///   - pathExtension: The path extension of the strategy's format, if any.
  ///   - snapshotDirectory: An optional override for the directory holding reference snapshots. By
  ///     default snapshots are saved in a directory with the same name as the test file, inside a
  ///     `__Snapshots__` directory that sits next to the test file.
  ///   - filePath: The file the assertion was made in.
  ///   - testName: The function the assertion was made in.
  init(
    named name: String?,
    argument: (any LosslessStringConvertible)? = nil,
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
    let sanitizedTestName = testName.sanitizePathComponent()

    // What the test name alone cannot say. Every run of a parameterized test shares that name, so it
    // names one file all of them write, and only the argument parts them. A test that is not
    // parameterized has nothing to part, and neither has an argument that sanitizes away to nothing.
    let isParameterized = Test.Case.current?.isParameterized == true
    let argumentComponent = isParameterized ? argument.flatMap(pathComponent(for:)) : nil

    var stem = sanitizedTestName
    if let argumentComponent {
      stem += ".\(argumentComponent)"
    }

    var refusal: String?
    if let name {
      stem += ".\(name.sanitizePathComponent())"
    } else if isParameterized && argumentComponent == nil {
      // The runs happen in parallel, so a number drawn across them is the order they happened to
      // start in, and it stands for a different argument the next time. With no argument to name the
      // snapshot after, the only honest number is none.
      refusal = """
        A parameterized test cannot number its snapshots, because its cases run in parallel and a \
        number would stand for a different argument on every run. Name this snapshot after the \
        argument it was taken from.
        """
    } else {
      // Counted off the argument as well as the test, so that each run numbers its own snapshots.
      // Within one run the count follows the order the body takes them in, which is the same on every
      // run.
      stem += ".\(register.claim(snapshotDirectoryURL.appending(path: stem).absoluteString))"
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

/// The path component an argument names, or `nil` when it does not survive sanitizing into one.
///
/// An argument such as `"/"` is all separators, and what is left of it once they are gone cannot name
/// anything. Refusing is left to the caller, which is where the alternatives are known.
private func pathComponent(for argument: any LosslessStringConvertible) -> String? {
  let component = argument.description.sanitizePathComponent()
  return component.isEmpty ? nil : component
}

private extension String {
  func sanitizePathComponent() -> String {
    (split(separator: "(", maxSplits: 1).first.map(String.init) ?? self)
      .replacingOccurrences(of: "\\W+", with: "-", options: .regularExpression)
      .replacingOccurrences(of: "^-|-$", with: "", options: .regularExpression)
  }
}
