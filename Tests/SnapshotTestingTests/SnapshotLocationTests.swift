import Foundation
import Testing

@testable import SnapshotTesting

/// Covers how an assertion derives the reference file it reads from and writes to.
///
/// `snapshotURL` reports the file that was resolved, so none of this needs a committed reference: a
/// scratch directory is planted with the rungs a case is about. Every case snapshots the same value,
/// because what is being asserted is the name, never the content.
@Suite(.serialized)
struct SnapshotLocationTests {
  private func scratchDirectory() -> URL {
    FileManager.default.temporaryDirectory
      .appending(path: "SnapshotLocationTests-\(UUID().uuidString)", directoryHint: .isDirectory)
  }

  /// Creates `name` inside `directory`, standing in for a reference recorded earlier.
  private func plant(_ name: String, in directory: URL) throws {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try Data("planted".utf8).write(to: directory.appending(path: name))
  }

  @Test func `a snapshot is named after the test that took it`() async {
    let directory = scratchDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }

    let result = await verifySnapshot(of: 1, as: .json, snapshotDirectory: directory.path)

    #expect(
      result.snapshotURL.lastPathComponent == "a-snapshot-is-named-after-the-test-that-took-it.json"
    )
  }

  @Test func `a strategy whose extension is ambiguous names itself too`() async {
    let directory = scratchDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }

    let result = await verifySnapshot(of: 1, as: .dump, snapshotDirectory: directory.path)

    #expect(
      result.snapshotURL.lastPathComponent
        == "a-strategy-whose-extension-is-ambiguous-names-itself-too.dump.txt"
    )
  }

  @Test func `a suffix is appended to the derived name`() async {
    let directory = scratchDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }

    let result = await verifySnapshot(
      of: 1,
      as: .dump,
      suffixed: "the suffix",
      snapshotDirectory: directory.path
    )

    #expect(
      result.snapshotURL.lastPathComponent
        == "a-suffix-is-appended-to-the-derived-name.dump.the-suffix.txt"
    )
  }

  @Test func `a snapshot with no reference yet is shared by every platform`() async {
    let directory = scratchDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }

    let result = await verifySnapshot(of: 1, as: .json, snapshotDirectory: directory.path)

    #expect(
      result.snapshotURL.lastPathComponent
        == "a-snapshot-with-no-reference-yet-is-shared-by-every-platform.json"
    )
  }

  @Test func `a reference named after this platform is preferred to a shared one`() async throws {
    let platform = try #require(SnapshotPlatform.name)
    let directory = scratchDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }

    let stem = "a-reference-named-after-this-platform-is-preferred-to-a-shared-one"
    try plant("\(stem).json", in: directory)
    try plant("\(stem).\(platform).json", in: directory)

    let result = await verifySnapshot(of: 1, as: .json, snapshotDirectory: directory.path)

    #expect(result.snapshotURL.lastPathComponent == "\(stem).\(platform).json")
  }

  @Test func `a reference named after this version is preferred to one named after the platform`()
    async throws
  {
    let platform = try #require(SnapshotPlatform.name)
    let versioned = try #require(SnapshotPlatform.versionedName)
    let directory = scratchDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }

    let stem = "a-reference-named-after-this-version-is-preferred-to-one-named-after-the-platform"
    try plant("\(stem).json", in: directory)
    try plant("\(stem).\(platform).json", in: directory)
    try plant("\(stem).\(versioned).json", in: directory)

    let result = await verifySnapshot(of: 1, as: .json, snapshotDirectory: directory.path)

    #expect(result.snapshotURL.lastPathComponent == "\(stem).\(versioned).json")
  }

  // A reference for another platform says nothing about this one, and must not draw this run away
  // from the file it shares with everyone else.
  @Test func `a reference named after another platform is ignored`() async throws {
    let directory = scratchDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }

    let stem = "a-reference-named-after-another-platform-is-ignored"
    let elsewhere = SnapshotPlatform.name == "linux" ? "macos" : "linux"
    try plant("\(stem).\(elsewhere).json", in: directory)

    let result = await verifySnapshot(of: 1, as: .json, snapshotDirectory: directory.path)

    #expect(result.snapshotURL.lastPathComponent == "\(stem).json")
  }

  // The hazard the derivation exists to avoid: inserting an assertion above another one must not
  // move the file the second one has been comparing against.
  @Test func `a name does not depend on what else the test snapshots`() async {
    let directory = scratchDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }

    let inserted = await verifySnapshot(of: 1, as: .json, snapshotDirectory: directory.path)
    let existing = await verifySnapshot(of: 1, as: .dump, snapshotDirectory: directory.path)

    let stem = "a-name-does-not-depend-on-what-else-the-test-snapshots"
    #expect(inserted.snapshotURL.lastPathComponent == "\(stem).json")
    #expect(existing.snapshotURL.lastPathComponent == "\(stem).dump.txt")
  }

  @Test func `two snapshots deriving one name are refused rather than sharing a reference`() async {
    let directory = scratchDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }

    let first = await verifySnapshot(of: 1, as: .json, snapshotDirectory: directory.path)
    let second = await verifySnapshot(of: 2, as: .json, snapshotDirectory: directory.path)

    #expect(first.snapshotURL == second.snapshotURL)
    #expect(first.outcome == .referenceRecorded)

    let name = "two-snapshots-deriving-one-name-are-refused-rather-than-sharing-a-reference.json"
    #expect(
      second.outcome
        == .errored(
          """
          An earlier snapshot in this test was already written to '\(name)'. Pass 'suffixed:' to \
          tell them apart.
          """
        )
    )

    // The first snapshot's reference survives, which is the point of refusing before comparing.
    let reference = try? Data(contentsOf: first.snapshotURL)
    #expect(reference == Data("1".utf8))
  }

  // An explicit suffix takes a snapshot out of that rule: a test can watch one reference be recorded
  // and then matched.
  @Test func `a suffixed snapshot may be taken twice`() async {
    let directory = scratchDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }

    let recorded = await verifySnapshot(
      of: 1,
      as: .json,
      suffixed: "twice",
      snapshotDirectory: directory.path
    )
    let matched = await verifySnapshot(
      of: 1,
      as: .json,
      suffixed: "twice",
      snapshotDirectory: directory.path
    )

    #expect(recorded.outcome == .referenceRecorded)
    #expect(matched.outcome == .matched)
  }
}
