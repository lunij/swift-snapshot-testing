import Foundation
import Testing

@testable import SnapshotTesting

struct SnapshotLocationTests {
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

  /// Two snapshots given one name resolve to one reference, and the second is compared against what
  /// the first recorded. Reporting that as the collision it is comes later; this pins what happens
  /// until it does.
  @Test func `a repeated name resolves to the reference the first one recorded`() async {
    let directory = scratchDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }

    let first = await verifySnapshot(
      of: 1,
      as: .json,
      named: "twice",
      record: .missing,
      snapshotDirectory: directory.path
    )
    let second = await verifySnapshot(
      of: 1,
      as: .json,
      named: "twice",
      record: .never,
      snapshotDirectory: directory.path
    )

    #expect(first.outcome == .referenceRecorded)
    #expect(second.outcome == .matched)
    #expect(first.snapshotURL == second.snapshotURL)
  }

  @Test(arguments: [1, 2, 3])
  func `adds an argument to the snapshot name`(value: Int) {
    let location = createSnapshotLocation(argument: value)

    #expect(location.refusal == nil)
    #expect(
      location.snapshotURL.lastPathComponent
        == "adds-an-argument-to-the-snapshot-name.\(value).1.json"
    )
  }

  @Test(arguments: [1, 2])
  func `every argument numbers its snapshots from one`(value: Int) {
    let first = createSnapshotLocation(argument: value)
    let second = createSnapshotLocation(argument: value)

    #expect(first.snapshotURL.lastPathComponent.hasSuffix(".\(value).1.json"))
    #expect(second.snapshotURL.lastPathComponent.hasSuffix(".\(value).2.json"))
  }

  @Test(arguments: [("plain", "plain"), ("two words", "two-words"), ("a/b", "a-b")])
  func `adds string arguments to the snapshot name`(value: String, component: String) {
    let location = createSnapshotLocation(argument: value)

    #expect(
      location.snapshotURL.lastPathComponent
        == "adds-string-arguments-to-the-snapshot-name.\(component).1.json"
    )
  }

  /// An argument made of nothing but separators leaves no component behind, so it identifies a
  /// snapshot no better than a number would.
  @Test(arguments: ["/", " ", ""])
  func `an argument that sanitizes away identifies nothing`(value: String) {
    #expect(createSnapshotLocation(argument: value).refusal == parameterizedRefusal)
  }

  /// Every case has to be refused, so every argument is asserted. Nothing reaches the disk: a
  /// snapshot that cannot be identified is not taken at all.
  @Test(arguments: [1, 2, 3])
  func `an unnamed snapshot in a parameterized test is refused`(value: Int) async {
    let directory = scratchDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }

    let result = await verifySnapshot(of: value, as: .json, snapshotDirectory: directory.path)

    #expect(result.outcome == .errored(parameterizedRefusal))
    #expect(!FileManager.default.fileExists(atPath: directory.path))
  }

  /// Numbering used to reset per case, or not, depending on whether an unrelated configuration trait
  /// happened to be applied. Neither branch produced a number worth having, so the refusal has to
  /// hold either way.
  @Suite(.snapshotRecord(.failed), .snapshotDiffTool(.ksdiff))
  struct UnderAConfigurationTrait {
    @Test(arguments: [1, 2, 3])
    func `an unnamed snapshot in a parameterized test is refused`(value: Int) async {
      let directory = scratchDirectory()
      defer { try? FileManager.default.removeItem(at: directory) }

      let result = await verifySnapshot(of: value, as: .json, snapshotDirectory: directory.path)

      #expect(result.outcome == .errored(parameterizedRefusal))
      #expect(!FileManager.default.fileExists(atPath: directory.path))
    }
  }
}

// MARK: - Private

private func scratchDirectory() -> URL {
  FileManager.default.temporaryDirectory
    .appending(path: "SnapshotLocationTests-\(UUID().uuidString)", directoryHint: .isDirectory)
}

private func createSnapshotLocation(
  argument: (any LosslessStringConvertible)?,
  testName: String = #function
) -> SnapshotLocation {
  SnapshotLocation(
    named: nil,
    argument: argument,
    pathExtension: "json",
    snapshotDirectory: "/derived",
    filePath: #filePath,
    testName: testName
  )
}

/// The reason a parameterized test's unnamed snapshot is refused, worded as `SnapshotLocation` words
/// it.
private let parameterizedRefusal = """
  A parameterized test cannot number its snapshots, because its cases run in parallel and a number \
  would stand for a different argument on every run. Name this snapshot after the argument it was \
  taken from.
  """
