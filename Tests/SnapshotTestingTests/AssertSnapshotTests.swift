import Foundation
import SnapshotTesting
import Testing

@Suite(.snapshotRecord(.failed), .snapshotDiffTool(.ksdiff))
struct AssertSnapshotTests {
  @Test(arguments: [1, 2, 3])
  func `the argument names the reference`(value: Int) async {
    await assertSnapshot(of: value, as: .json, argument: value)
  }

  /// `verifySnapshot` is the documented extension point, so a third-party helper has to be able to
  /// read the derived path for itself rather than infer it from what appeared on disk.
  @Test(arguments: [1, 2, 3])
  func `the argument reaches the derived path`(value: Int) async {
    let directory = scratchDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }

    let result = await verifySnapshot(
      of: value,
      as: .json,
      argument: value,
      record: .missing,
      snapshotDirectory: directory.path
    )

    #expect(result.outcome == .referenceRecorded)
    #expect(
      result.snapshotURL.lastPathComponent
        == "the-argument-reaches-the-derived-path.\(value).1.json"
    )
    #expect(FileManager.default.fileExists(atPath: result.snapshotURL.path))
  }

  /// With no argument to name it after, the location refuses. That reaches the caller as an outcome
  /// rather than a reported issue, and nothing is written, because the value is never evaluated.
  @Test(arguments: [1, 2, 3])
  func `an unnamed snapshot without an argument is refused`(value: Int) async {
    let directory = scratchDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }

    let result = await verifySnapshot(
      of: value,
      as: .json,
      record: .missing,
      snapshotDirectory: directory.path
    )

    #expect(result.outcome == .errored(parameterizedRefusal))
    #expect(!FileManager.default.fileExists(atPath: directory.path))
  }
}

// MARK: - Private

private func scratchDirectory() -> URL {
  FileManager.default.temporaryDirectory
    .appending(path: "AssertSnapshotTests-\(UUID().uuidString)", directoryHint: .isDirectory)
}

/// The reason a parameterized test's unnamed snapshot is refused, worded as the derived location
/// words it.
private let parameterizedRefusal = """
  A parameterized test cannot number its snapshots, because its cases run in parallel and a number \
  would stand for a different argument on every run. Name this snapshot after the argument it was \
  taken from.
  """
