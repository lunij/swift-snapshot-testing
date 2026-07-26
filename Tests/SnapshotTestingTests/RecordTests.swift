import Foundation
import SnapshotTesting
import Testing

@MainActor
@Suite(.serialized, .snapshots(record: .failed, diffTool: .ksdiff))
struct RecordTests {

  private func withSnapshotURL(
    testName: String = #function,
    filePath: StaticString = #filePath,
    _ body: (URL) async throws -> Void
  ) async rethrows {
    let sanitizedName =
      testName
      .replacing(/\W+/, with: "-")
      .replacing(/^-|-$/, with: "")
    let fileURL = URL(filePath: filePath.description)
    let testClassName = fileURL.deletingPathExtension().lastPathComponent
    let testDirectory =
      fileURL
      .deletingLastPathComponent()
      .appending(path: "__Snapshots__")
      .appending(path: testClassName)
    let snapshotURL = testDirectory.appending(path: "\(sanitizedName).1.json")
    try? FileManager.default.removeItem(at: testDirectory)
    try? FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: testDirectory) }
    try await body(snapshotURL)
  }

  @Test func `record set to "never"`() async {
    await withSnapshotURL { snapshotURL in
      await withKnownIssue {
        await withSnapshotTesting(record: .never) {
          await assertSnapshot(of: 42, as: .json)
        }
      } matching: { issue in
        issue.description.contains("No reference was found on disk. New snapshot was not recorded because recording is disabled")
      }
      #expect(!FileManager.default.fileExists(atPath: snapshotURL.path))
    }
  }

  @Test func `record set to "missing" while reference file does not exist`() async throws {
    try await withSnapshotURL { snapshotURL in
      await withKnownIssue {
        await withSnapshotTesting(record: .missing) {
          await assertSnapshot(of: 42, as: .json)
        }
      } matching: { issue in
        issue.description.hasPrefix("Issue recorded (error): No reference was found on disk. Automatically recorded snapshot: …")
      }
      let content = try String(decoding: Data(contentsOf: snapshotURL), as: UTF8.self)
      #expect(content == "42")
    }
  }

  @Test func `record set to "missing" while reference file does exist`() async throws {
    try await withSnapshotURL { snapshotURL in
      try Data("999".utf8).write(to: snapshotURL)
      await withKnownIssue {
        await withSnapshotTesting(record: .missing) {
          await assertSnapshot(of: 42, as: .json)
        }
      } matching: { issue in
        issue.description.hasPrefix("Issue recorded (error): Text does not match reference (+1 −1 lines).")
      }
      let content = try String(decoding: Data(contentsOf: snapshotURL), as: UTF8.self)
      #expect(content == "999")
    }
  }

  @Test func `record set to "all" while reference file does not exist`() async throws {
    try await withSnapshotURL { snapshotURL in
      await withKnownIssue {
        await withSnapshotTesting(record: .all) {
          await assertSnapshot(of: 42, as: .json)
        }
      } matching: { issue in
        issue.description.hasPrefix("Issue recorded (error): Record mode is on. Automatically recorded snapshot: …")
      }
      let content = try String(decoding: Data(contentsOf: snapshotURL), as: UTF8.self)
      #expect(content == "42")
    }
  }

  @Test func `record set to "all" while reference file does exist`() async throws {
    try await withSnapshotURL { snapshotURL in
      try Data("999".utf8).write(to: snapshotURL)
      await withKnownIssue {
        await withSnapshotTesting(record: .all) {
          await assertSnapshot(of: 42, as: .json)
        }
      } matching: { issue in
        issue.description.hasPrefix("Issue recorded (error): Record mode is on. Automatically recorded snapshot: …")
      }
      let content = try String(decoding: Data(contentsOf: snapshotURL), as: UTF8.self)
      #expect(content == "42")
    }
  }

  @Test func `record set to "failed" during failure`() async throws {
    try await withSnapshotURL { snapshotURL in
      try Data("999".utf8).write(to: snapshotURL)
      await withKnownIssue {
        await withSnapshotTesting(record: .failed) {
          await assertSnapshot(of: 42, as: .json)
        }
      } matching: { issue in
        issue.description.hasPrefix("Issue recorded (error): Text does not match reference (+1 −1 lines). A new snapshot was automatically recorded.")
      }
      let content = try String(decoding: Data(contentsOf: snapshotURL), as: UTF8.self)
      #expect(content == "42")
    }
  }

  @Test func `record set to "failed" during success`() async throws {
    try await withSnapshotURL { snapshotURL in
      try Data("42".utf8).write(to: snapshotURL)
      let modifiedDate =
        try FileManager.default.attributesOfItem(atPath: snapshotURL.path)[.modificationDate]
        as? Date
      await withSnapshotTesting(record: .failed) {
        await assertSnapshot(of: 42, as: .json)
      }
      let content = try String(decoding: Data(contentsOf: snapshotURL), as: UTF8.self)
      #expect(content == "42")
      let newModifiedDate =
        try FileManager.default.attributesOfItem(atPath: snapshotURL.path)[.modificationDate]
        as? Date
      #expect(newModifiedDate == modifiedDate)
    }
  }

  @Test func `record set to "failed" during missing reference file`() async throws {
    try await withSnapshotURL { snapshotURL in
      await withKnownIssue {
        await withSnapshotTesting(record: .failed) {
          await assertSnapshot(of: 42, as: .json)
        }
      } matching: { issue in
        issue.description.hasPrefix("Issue recorded (error): No reference was found on disk. Automatically recorded snapshot: …")
      }
      let content = try String(decoding: Data(contentsOf: snapshotURL), as: UTF8.self)
      #expect(content == "42")
    }
  }
}
