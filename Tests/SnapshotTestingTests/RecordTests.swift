import SnapshotTesting
import XCTest

@MainActor
class RecordTests: BaseTestCase {
  nonisolated(unsafe) var snapshotURL: URL!

  override func setUp() {
    super.setUp()

    let testName = String(
      self.name
        .split(separator: " ")
        .flatMap { String($0).split(separator: ".") }
        .last!
    )
    .prefix(while: { $0 != "]" })
    let fileURL = URL(fileURLWithPath: #filePath, isDirectory: false)
    let testClassName = fileURL.deletingPathExtension().lastPathComponent
    let testDirectory =
      fileURL
      .deletingLastPathComponent()
      .appendingPathComponent("__Snapshots__")
      .appendingPathComponent(testClassName)
    snapshotURL =
      testDirectory
      .appendingPathComponent("\(testName).1.json")
    try? FileManager.default
      .removeItem(at: snapshotURL.deletingLastPathComponent())
    try? FileManager.default
      .createDirectory(at: testDirectory, withIntermediateDirectories: true)
  }

  override func tearDown() {
    super.tearDown()
    try? FileManager.default
      .removeItem(at: snapshotURL.deletingLastPathComponent())
  }

  #if canImport(Darwin)
  func testRecordNever() async {
    XCTExpectFailure(issueMatcher: {
      $0.compactDescription == """
        failed - No reference was found on disk. New snapshot was not recorded because recording is disabled
        """
    })
    await withSnapshotTesting(record: .never) {
      await assertSnapshot(of: 42, as: .json)
    }

    XCTAssertEqual(
      FileManager.default.fileExists(atPath: snapshotURL.path),
      false
    )
  }
  #endif

  #if canImport(Darwin)
  func testRecordMissing() async {
    XCTExpectFailure(issueMatcher: {
      $0.compactDescription.hasPrefix(
        """
        failed - No reference was found on disk. Automatically recorded snapshot: …
        """
      )
    })
    await withSnapshotTesting(record: .missing) {
      await assertSnapshot(of: 42, as: .json)
    }

    try XCTAssertEqual(
      String(decoding: Data(contentsOf: snapshotURL), as: UTF8.self),
      "42"
    )
  }
  #endif

  #if canImport(Darwin)
  func testRecordMissing_ExistingFile() async throws {
    try Data("999".utf8).write(to: snapshotURL)

    XCTExpectFailure(issueMatcher: {
      $0.compactDescription.hasPrefix(
        """
        failed - Text does not match reference (+1 −1 lines).
        """
      )
    })
    await withSnapshotTesting(record: .missing) {
      await assertSnapshot(of: 42, as: .json)
    }

    try XCTAssertEqual(
      String(decoding: Data(contentsOf: snapshotURL), as: UTF8.self),
      "999"
    )
  }
  #endif

  #if canImport(Darwin)
  func testRecordAll_Fresh() async throws {
    XCTExpectFailure(issueMatcher: {
      $0.compactDescription.hasPrefix(
        """
        failed - Record mode is on. Automatically recorded snapshot: …
        """
      )
    })
    await withSnapshotTesting(record: .all) {
      await assertSnapshot(of: 42, as: .json)
    }

    try XCTAssertEqual(
      String(decoding: Data(contentsOf: snapshotURL), as: UTF8.self),
      "42"
    )
  }
  #endif

  #if canImport(Darwin)
  func testRecordAll_Overwrite() async throws {
    try Data("999".utf8).write(to: snapshotURL)

    XCTExpectFailure(issueMatcher: {
      $0.compactDescription.hasPrefix(
        """
        failed - Record mode is on. Automatically recorded snapshot: …
        """
      )
    })
    await withSnapshotTesting(record: .all) {
      await assertSnapshot(of: 42, as: .json)
    }

    try XCTAssertEqual(
      String(decoding: Data(contentsOf: snapshotURL), as: UTF8.self),
      "42"
    )
  }
  #endif

  #if canImport(Darwin)
  func testRecordFailed_WhenFailure() async throws {
    try Data("999".utf8).write(to: snapshotURL)

    XCTExpectFailure(issueMatcher: {
      $0.compactDescription.hasPrefix(
        """
        failed - Text does not match reference (+1 −1 lines). A new snapshot was automatically recorded.
        """
      )
    })
    await withSnapshotTesting(record: .failed) {
      await assertSnapshot(of: 42, as: .json)
    }

    try XCTAssertEqual(
      String(decoding: Data(contentsOf: snapshotURL), as: UTF8.self),
      "42"
    )
  }
  #endif

  func testRecordFailed_NoFailure() async throws {
    #if os(Android)
    throw XCTSkip("cannot save next to file on Android")
    #endif
    try Data("42".utf8).write(to: snapshotURL)
    let modifiedDate =
      try FileManager.default
      .attributesOfItem(atPath: snapshotURL.path)[FileAttributeKey.modificationDate] as! Date

    await withSnapshotTesting(record: .failed) {
      await assertSnapshot(of: 42, as: .json)
    }

    try XCTAssertEqual(
      String(decoding: Data(contentsOf: snapshotURL), as: UTF8.self),
      "42"
    )
    XCTAssertEqual(
      try FileManager.default
        .attributesOfItem(atPath: snapshotURL.path)[FileAttributeKey.modificationDate] as! Date,
      modifiedDate
    )
  }

  #if canImport(Darwin)
  func testRecordFailed_MissingFile() async throws {
    XCTExpectFailure(issueMatcher: {
      $0.compactDescription.hasPrefix(
        """
        failed - No reference was found on disk. Automatically recorded snapshot: …
        """
      )
    })
    await withSnapshotTesting(record: .failed) {
      await assertSnapshot(of: 42, as: .json)
    }

    try XCTAssertEqual(
      String(decoding: Data(contentsOf: snapshotURL), as: UTF8.self),
      "42"
    )
  }
  #endif
}
