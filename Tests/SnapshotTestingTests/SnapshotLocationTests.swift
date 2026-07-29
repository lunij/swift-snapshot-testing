import Foundation
import SnapshotTesting
import Testing

/// Covers how an assertion derives the reference file it reads from and writes to.
///
/// A snapshot is identified either by an explicit name or, without one, by a counter that numbers
/// the snapshots a test takes in order. Both branches are asserted here. `snapshotURL` reports the
/// derived path, so neither test needs a committed reference file.
@Suite(.serialized)
struct SnapshotLocationTests {
  private func scratchDirectory() -> URL {
    FileManager.default.temporaryDirectory
      .appending(path: "SnapshotLocationTests-\(UUID().uuidString)", directoryHint: .isDirectory)
  }

  @Test func `unnamed snapshots are numbered in the order they are taken`() async {
    let directory = scratchDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }

    let first = await verifySnapshot(of: 1, as: .json, snapshotDirectory: directory.path)
    let second = await verifySnapshot(of: 2, as: .json, snapshotDirectory: directory.path)

    #expect(first.snapshotURL.lastPathComponent == "unnamed-snapshots-are-numbered-in-the-order-they-are-taken.1.json")
    #expect(second.snapshotURL.lastPathComponent == "unnamed-snapshots-are-numbered-in-the-order-they-are-taken.2.json")
  }

  @Test func `a named snapshot is identified by its name rather than a number`() async {
    let directory = scratchDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }

    let result = await verifySnapshot(of: 1, as: .json, named: "the name", snapshotDirectory: directory.path)

    #expect(result.snapshotURL.lastPathComponent == "a-named-snapshot-is-identified-by-its-name-rather-than-a-number.the-name.json")
  }
}
