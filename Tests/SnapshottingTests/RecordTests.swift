import Foundation
import Snapshotting
import Testing

@MainActor
@Suite(.serialized)
struct RecordTests {
  /// Runs `body` against a reference URL inside a scratch directory that is removed afterwards.
  ///
  /// The reference does not exist until a test writes it, which is what most of these tests are
  /// about.
  private func withSnapshotURL(
    _ body: (URL) async throws -> Void
  ) async rethrows {
    let directory = FileManager.default.temporaryDirectory
      .appending(path: "RecordTests-\(UUID().uuidString)", directoryHint: .isDirectory)
    defer { try? FileManager.default.removeItem(at: directory) }
    try await body(directory.appending(path: "snapshot.json"))
  }

  private func compare(
    _ value: Int,
    against snapshotURL: URL,
    isolation: isolated (any Actor)? = #isolation
  ) async -> SnapshotResult {
    await compareSnapshot(
      of: value,
      as: .json,
      against: snapshotURL,
      artifactDirectory: snapshotURL.deletingLastPathComponent().appending(path: "artifacts")
    )
  }

  private func contents(of url: URL) throws -> String {
    try String(decoding: Data(contentsOf: url), as: UTF8.self)
  }

  @Test func `record set to "never"`() async {
    await withSnapshotURL { snapshotURL in
      let result = await withSnapshotConfiguration(record: .never) {
        await compare(42, against: snapshotURL)
      }
      #expect(result.outcome == .referenceMissing)
      #expect(!result.recorded)
      #expect(!FileManager.default.fileExists(atPath: snapshotURL.path))
    }
  }

  @Test func `record set to "missing" while reference file does not exist`() async throws {
    try await withSnapshotURL { snapshotURL in
      let result = await withSnapshotConfiguration(record: .missing) {
        await compare(42, against: snapshotURL)
      }
      #expect(result.outcome == .referenceRecorded)
      #expect(result.recorded)
      let content = try contents(of: snapshotURL)
      #expect(content == "42")
    }
  }

  @Test func `record set to "missing" while reference file does exist`() async throws {
    try await withSnapshotURL { snapshotURL in
      try FileManager.default.createDirectory(at: snapshotURL.deletingLastPathComponent(), withIntermediateDirectories: true)
      try Data("999".utf8).write(to: snapshotURL)
      let result = await withSnapshotConfiguration(record: .missing) {
        await compare(42, against: snapshotURL)
      }
      #expect(result.outcome.mismatch?.reason == "Text does not match reference (+1 −1 lines).")
      #expect(!result.recorded)
      let content = try contents(of: snapshotURL)
      #expect(content == "999")
    }
  }

  @Test func `record set to "all" while reference file does not exist`() async throws {
    try await withSnapshotURL { snapshotURL in
      let result = await withSnapshotConfiguration(record: .all) {
        await compare(42, against: snapshotURL)
      }
      #expect(result.outcome == .recordModeOn)
      #expect(result.recorded)
      let content = try contents(of: snapshotURL)
      #expect(content == "42")
    }
  }

  @Test func `record set to "all" while reference file does exist`() async throws {
    try await withSnapshotURL { snapshotURL in
      try FileManager.default.createDirectory(at: snapshotURL.deletingLastPathComponent(), withIntermediateDirectories: true)
      try Data("999".utf8).write(to: snapshotURL)
      let result = await withSnapshotConfiguration(record: .all) {
        await compare(42, against: snapshotURL)
      }
      #expect(result.outcome == .recordModeOn)
      #expect(result.recorded)
      let content = try contents(of: snapshotURL)
      #expect(content == "42")
    }
  }

  @Test func `record set to "failed" during failure`() async throws {
    try await withSnapshotURL { snapshotURL in
      try FileManager.default.createDirectory(at: snapshotURL.deletingLastPathComponent(), withIntermediateDirectories: true)
      try Data("999".utf8).write(to: snapshotURL)
      let result = await withSnapshotConfiguration(record: .failed) {
        await compare(42, against: snapshotURL)
      }
      #expect(result.outcome.mismatch?.reason == "Text does not match reference (+1 −1 lines).")
      #expect(result.recorded)
      let content = try contents(of: snapshotURL)
      #expect(content == "42")
    }
  }

  @Test func `record set to "failed" during success`() async throws {
    try await withSnapshotURL { snapshotURL in
      try FileManager.default.createDirectory(at: snapshotURL.deletingLastPathComponent(), withIntermediateDirectories: true)
      try Data("42".utf8).write(to: snapshotURL)
      let modifiedDate =
        try FileManager.default.attributesOfItem(atPath: snapshotURL.path)[.modificationDate] as? Date
      let result = await withSnapshotConfiguration(record: .failed) {
        await compare(42, against: snapshotURL)
      }
      #expect(result.outcome == .matched)
      #expect(!result.recorded)
      let content = try contents(of: snapshotURL)
      #expect(content == "42")
      let newModifiedDate =
        try FileManager.default.attributesOfItem(atPath: snapshotURL.path)[.modificationDate] as? Date
      #expect(newModifiedDate == modifiedDate)
    }
  }

  @Test func `record set to "failed" during missing reference file`() async throws {
    try await withSnapshotURL { snapshotURL in
      let result = await withSnapshotConfiguration(record: .failed) {
        await compare(42, against: snapshotURL)
      }
      #expect(result.outcome == .referenceRecorded)
      #expect(result.recorded)
      let content = try contents(of: snapshotURL)
      #expect(content == "42")
    }
  }
}
