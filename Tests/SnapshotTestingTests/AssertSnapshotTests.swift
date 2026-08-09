import Foundation
import SnapshotTesting
import Testing

@Suite(.snapshotRecord(.failed), .snapshotDiffTool(.ksdiff))
struct AssertSnapshotTests {
  /// A value that describes itself losslessly is the argument its case runs under, so a test
  /// parameterized over one does not have to hand it in.
  @Test(arguments: [1, 2, 3])
  func `the value names the reference`(value: Int) async {
    await assertSnapshot(of: value, as: .json)
  }

  /// `verifySnapshot` is the documented extension point, so a third-party helper has to be able to
  /// read the derived path for itself rather than infer it from what appeared on disk.
  @Test(arguments: [1, 2, 3])
  func `the value reaches the derived path`(value: Int) async {
    let directory = scratchDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }

    let result = await verifySnapshot(
      of: value,
      as: .json,
      record: .missing,
      snapshotDirectory: directory.path
    )

    #expect(result.outcome == .referenceRecorded)
    #expect(
      result.snapshotURL.lastPathComponent == "the-value-reaches-the-derived-path.\(value).1.json"
    )
    #expect(FileManager.default.fileExists(atPath: result.snapshotURL.path))
  }

  /// The value is not always what a test is parameterized over. Every case snapshots the same value
  /// here, so only the argument the caller hands in parts them.
  @Test(arguments: [1, 2, 3])
  func `an argument outranks the value`(value: Int) async {
    let directory = scratchDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }

    let result = await verifySnapshot(
      of: "shared by every case",
      as: .json,
      argument: value,
      record: .missing,
      snapshotDirectory: directory.path
    )

    #expect(result.outcome == .referenceRecorded)
    #expect(
      result.snapshotURL.lastPathComponent == "an-argument-outranks-the-value.\(value).1.json"
    )
  }

  /// With neither an argument to name it after nor a value able to name itself, the location
  /// refuses. That reaches the caller as an outcome rather than a reported issue, and nothing is
  /// written, because the value is never rendered.
  @Test(arguments: [1, 2, 3])
  func `an unnamed snapshot of a value that cannot name itself is refused`(value: Int) async {
    let directory = scratchDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }

    let result = await verifySnapshot(
      of: [value],
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
