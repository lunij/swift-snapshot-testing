import Foundation
import Testing

@testable import SnapshotTesting

/// Covers the advice a mismatch adds when the reference it failed against is shared by every
/// platform.
///
/// The hint is driven with a location and a result rather than through an assertion, because what it
/// has to get right is the state on disk a record mode leaves behind, and reaching the recording
/// branch through `assertSnapshot` would mean committing a reference for it to overwrite. That the
/// hint reaches a failure at all is proven end to end by `SwiftTestingTests.reports on mismatch`.
struct SharedReferenceHintTests {
  /// Nothing wrote to the reference, so it still holds whatever platform recorded it and this run's
  /// output exists only as a failure artifact.
  @Test func `a shared reference this run left alone keeps its name`() throws {
    let platform = try #require(SnapshotPlatform.name)
    let directory = scratchDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }

    let location = location(in: directory)
    let hint = sharedReferenceHint(for: mismatch(at: location, recorded: false), at: location)

    let stem = "a-shared-reference-this-run-left-alone-keeps-its-name"
    #expect(
      hint == """
        '\(stem).json' is shared by every platform. If it differs because of the platform this ran \
        on, save this run's output as '\(stem).\(platform).json' and leave '\(stem).json' to the \
        platforms it matches.
        """
    )
  }

  /// The case the default record mode produces: the shared file has already been overwritten with
  /// this run's output by the time the hint is read. Naming it after the platform that recorded it
  /// would therefore label this run's output as another platform's, and leave that platform without
  /// a reference at all.
  @Test func `a shared reference this run recorded over has to be restored`() throws {
    let platform = try #require(SnapshotPlatform.name)
    let directory = scratchDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }

    let location = location(in: directory)
    let hint = sharedReferenceHint(for: mismatch(at: location, recorded: true), at: location)

    let stem = "a-shared-reference-this-run-recorded-over-has-to-be-restored"
    #expect(
      hint == """
        '\(stem).json' is shared by every platform, and this run has recorded over it. If it differs \
        because of the platform this ran on, rename '\(stem).json' to '\(stem).\(platform).json' — \
        it holds this run's output — and restore '\(stem).json', which every other platform still \
        reads, from version control.
        """
    )
  }

  // A reference that already names a platform is nobody else's, so a mismatch against it is a
  // mismatch and nothing more.
  @Test func `a reference named after this platform draws no hint`() throws {
    let platform = try #require(SnapshotPlatform.name)
    let directory = scratchDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }

    let stem = "a-reference-named-after-this-platform-draws-no-hint"
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try Data("planted".utf8).write(to: directory.appending(path: "\(stem).\(platform).json"))

    let location = location(in: directory)
    #expect(location.snapshotURL.lastPathComponent == "\(stem).\(platform).json")
    #expect(sharedReferenceHint(for: mismatch(at: location, recorded: true), at: location) == nil)
    #expect(sharedReferenceHint(for: mismatch(at: location, recorded: false), at: location) == nil)
  }

  @Test func `a value that matches its reference draws no hint`() {
    let directory = scratchDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }

    let location = location(in: directory)
    let result = SnapshotResult(outcome: .matched, snapshotURL: location.snapshotURL)

    #expect(sharedReferenceHint(for: result, at: location) == nil)
  }

  // MARK: - Private

  private func scratchDirectory() -> URL {
    FileManager.default.temporaryDirectory
      .appending(path: "SharedReferenceHintTests-\(UUID().uuidString)", directoryHint: .isDirectory)
  }

  private func location(in directory: URL, testName: String = #function) -> SnapshotLocation {
    SnapshotLocation(
      identifier: nil,
      suffixed: nil,
      pathExtension: "json",
      snapshotDirectory: directory.path,
      filePath: #filePath,
      testName: testName
    )
  }

  private func mismatch(at location: SnapshotLocation, recorded: Bool) -> SnapshotResult {
    SnapshotResult(
      outcome: .mismatched(SnapshotFailure(reason: "Snapshot does not match reference.")),
      snapshotURL: location.snapshotURL,
      recorded: recorded
    )
  }
}
