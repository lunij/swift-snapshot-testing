import Foundation
import Synchronization

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

#if canImport(Testing)
import Testing
#endif

@_spi(Internals)
public var _diffTool: SnapshotTestingConfiguration.DiffTool {
  get {
    #if canImport(Testing)
    if let test = Test.current {
      for trait in test.traits.reversed() {
        if let diffTool = (trait as? _SnapshotsTestTrait)?.configuration.diffTool {
          return diffTool
        }
      }
    }
    #endif
    return __diffTool.withLock { $0 }
  }
  set {
    __diffTool.withLock { $0 = newValue }
  }
}

private let __diffTool = Mutex<SnapshotTestingConfiguration.DiffTool>(.default)

@_spi(Internals)
public var _record: SnapshotTestingConfiguration.Record {
  get {
    #if canImport(Testing)
    if let test = Test.current {
      for trait in test.traits.reversed() {
        if let record = (trait as? _SnapshotsTestTrait)?.configuration.record {
          return record
        }
      }
    }
    #endif
    return __record.withLock { $0 }
  }
  set {
    __record.withLock { $0 = newValue }
  }
}

private let __record = Mutex<SnapshotTestingConfiguration.Record>(
  {
    if let value = ProcessInfo.processInfo.environment["SNAPSHOT_TESTING_RECORD"],
      let record = SnapshotTestingConfiguration.Record(rawValue: value)
    {
      return record
    }
    return .missing
  }()
)

/// Asserts that a given value matches a reference on disk.
///
/// - Parameters:
///   - value: A value to compare against a reference.
///   - snapshotting: A strategy for serializing, deserializing, and comparing values.
///   - name: An optional description of the snapshot.
///   - record: The record mode to use while asserting snapshots.
///   - fileID: The file ID in which failure occurred. Defaults to the file ID of the test case in
///     which this function was called.
///   - file: The file in which failure occurred. Defaults to the file path of the test case in
///     which this function was called.
///   - testName: The name of the test in which failure occurred. Defaults to the function name of
///     the test case in which this function was called.
///   - line: The line number on which failure occurred. Defaults to the line number on which this
///     function was called.
///   - column: The column on which failure occurred. Defaults to the column on which this function
///     was called.
public func assertSnapshot<Value, Format>(
  of value: @autoclosure () throws -> Value,
  as snapshotting: Snapshotting<Value, Format>,
  named name: String? = nil,
  record: SnapshotTestingConfiguration.Record? = nil,
  isolation: isolated (any Actor)? = #isolation,
  fileID: StaticString = #fileID,
  file filePath: StaticString = #filePath,
  testName: String = #function,
  line: UInt = #line,
  column: UInt = #column
) async {
  let failure = await verifySnapshot(
    of: try value(),
    as: snapshotting,
    named: name,
    record: record,
    isolation: isolation,
    fileID: fileID,
    file: filePath,
    testName: testName,
    line: line,
    column: column
  )
  guard let message = failure else { return }
  recordIssue(
    message,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column
  )
}

/// Asserts that a given value matches references on disk.
///
/// - Parameters:
///   - value: A value to compare against a reference.
///   - strategies: A dictionary of names and strategies for serializing, deserializing, and
///     comparing values.
///   - recording: The record mode to use while asserting snapshots.
///   - fileID: The file ID in which failure occurred. Defaults to the file ID of the test case in
///     which this function was called.
///   - file: The file in which failure occurred. Defaults to the file path of the test case in
///     which this function was called.
///   - testName: The name of the test in which failure occurred. Defaults to the function name of
///     the test case in which this function was called.
///   - line: The line number on which failure occurred. Defaults to the line number on which this
///     function was called.
///   - column: The column on which failure occurred. Defaults to the column on which this function
///     was called.
public func assertSnapshots<Value, Format>(
  of value: @autoclosure () throws -> Value,
  as strategies: [String: Snapshotting<Value, Format>],
  record: SnapshotTestingConfiguration.Record? = nil,
  isolation: isolated (any Actor)? = #isolation,
  fileID: StaticString = #fileID,
  file filePath: StaticString = #filePath,
  testName: String = #function,
  line: UInt = #line,
  column: UInt = #column
) async {
  for (name, strategy) in strategies {
    await assertSnapshot(
      of: try value(),
      as: strategy,
      named: name,
      record: record,
      isolation: isolation,
      fileID: fileID,
      file: filePath,
      testName: testName,
      line: line,
      column: column
    )
  }
}

/// Asserts that a given value matches references on disk.
///
/// - Parameters:
///   - value: A value to compare against a reference.
///   - strategies: An array of strategies for serializing, deserializing, and comparing values.
///   - record: The record mode to use while asserting snapshots.
///   - fileID: The file ID in which failure occurred. Defaults to the file ID of the test case in
///     which this function was called.
///   - file: The file in which failure occurred. Defaults to the file path of the test case in
///     which this function was called.
///   - testName: The name of the test in which failure occurred. Defaults to the function name of
///     the test case in which this function was called.
///   - line: The line number on which failure occurred. Defaults to the line number on which this
///     function was called.
///   - column: The column on which failure occurred. Defaults to the column on which this function
///     was called.
public func assertSnapshots<Value, Format>(
  of value: @autoclosure () throws -> Value,
  as strategies: [Snapshotting<Value, Format>],
  record: SnapshotTestingConfiguration.Record? = nil,
  isolation: isolated (any Actor)? = #isolation,
  fileID: StaticString = #fileID,
  file filePath: StaticString = #filePath,
  testName: String = #function,
  line: UInt = #line,
  column: UInt = #column
) async {
  for strategy in strategies {
    await assertSnapshot(
      of: try value(),
      as: strategy,
      record: record,
      isolation: isolation,
      fileID: fileID,
      file: filePath,
      testName: testName,
      line: line,
      column: column
    )
  }
}

/// Verifies that a given value matches a reference on disk.
///
/// Third party snapshot assert helpers can be built on top of this function. Simply invoke
/// `verifySnapshot` with your own arguments, and then invoke `XCTFail` with the string returned if
/// it is non-`nil`. For example, if you want the snapshot directory to be determined by an
/// environment variable, you can create your own assert helper like so:
///
/// ```swift
/// public func myAssertSnapshot<Value, Format>(
///   of value: @autoclosure () throws -> Value,
///   as snapshotting: Snapshotting<Value, Format>,
///   named name: String? = nil,
///   record: SnapshotTestingConfiguration.Record? = nil,
///   file: StaticString = #file,
///   testName: String = #function,
///   line: UInt = #line
///   ) async {
///
///     let snapshotDirectory = ProcessInfo.processInfo.environment["SNAPSHOT_REFERENCE_DIR"]! + "/" + #file
///     let failure = await verifySnapshot(
///       of: try value(),
///       as: snapshotting,
///       named: name,
///       record: record,
///       snapshotDirectory: snapshotDirectory,
///       file: file,
///       testName: testName
///     )
///     guard let message = failure else { return }
///     XCTFail(message, file: file, line: line)
/// }
/// ```
///
/// - Parameters:
///   - value: A value to compare against a reference.
///   - snapshotting: A strategy for serializing, deserializing, and comparing values.
///   - name: An optional description of the snapshot.
///   - record: The record mode to use while asserting snapshots.
///   - snapshotDirectory: Optional directory to save snapshots. By default snapshots will be saved
///     in a directory with the same name as the test file, and that directory will sit inside a
///     directory `__Snapshots__` that sits next to your test file.
///   - file: The file in which failure occurred. Defaults to the file name of the test case in
///     which this function was called.
///   - testName: The name of the test in which failure occurred. Defaults to the function name of
///     the test case in which this function was called.
///   - line: The line number on which failure occurred. Defaults to the line number on which this
///     function was called.
/// - Returns: A failure message or, if the value matches, nil.
public func verifySnapshot<Value, Format>(
  of value: @autoclosure () throws -> Value,
  as snapshotting: Snapshotting<Value, Format>,
  named name: String? = nil,
  record: SnapshotTestingConfiguration.Record? = nil,
  snapshotDirectory: String? = nil,
  isolation: isolated (any Actor)? = #isolation,
  fileID: StaticString = #fileID,
  file filePath: StaticString = #filePath,
  testName: String = #function,
  line: UInt = #line,
  column: UInt = #column
) async -> String? {
  let record = record ?? SnapshotTestingConfiguration.current?.record ?? _record
  return await withSnapshotTesting(record: record, isolation: isolation) { () async -> String? in
    do {
      let fileUrl = URL(fileURLWithPath: "\(filePath)", isDirectory: false)
      let fileName = fileUrl.deletingPathExtension().lastPathComponent

      #if os(Android)
      // When running tests on Android, the CI script copies the Tests/SnapshotTestingTests/__Snapshots__ up to the temporary folder
      let snapshotsBaseUrl = URL(
        fileURLWithPath: "/data/local/tmp/android-xctest",
        isDirectory: true
      )
      #else
      let snapshotsBaseUrl = fileUrl.deletingLastPathComponent()
      #endif

      let snapshotDirectoryUrl =
        snapshotDirectory.map { URL(fileURLWithPath: $0, isDirectory: true) }
        ?? snapshotsBaseUrl.appendingPathComponent("__Snapshots__").appendingPathComponent(fileName)

      let identifier: String
      if let name = name {
        identifier = sanitizePathComponent(name)
      } else {
        identifier = String(
          counter.next(for: snapshotDirectoryUrl.appendingPathComponent(testName).absoluteString)
        )
      }

      let testName = sanitizePathComponent(testName)
      var snapshotFileUrl =
        snapshotDirectoryUrl
        .appendingPathComponent("\(testName).\(identifier)")
      if let ext = snapshotting.pathExtension {
        snapshotFileUrl = snapshotFileUrl.appendingPathExtension(ext)
      }
      let fileManager = FileManager.default
      try fileManager.createDirectory(at: snapshotDirectoryUrl, withIntermediateDirectories: true)

      let snapshotValue = try value()
      let diffable = await snapshotting.snapshot(snapshotValue)

      func recordSnapshot(writeToDisk: Bool) async throws {
        let snapshotData = try snapshotting.serializer.toData(diffable)

        if writeToDisk {
          try snapshotData.write(to: snapshotFileUrl)
        }

        #if !os(Android) && !os(Linux) && !os(Windows)
        if ProcessInfo.processInfo.environment.keys.contains("__XCODE_BUILT_PRODUCTS_DIR_PATHS") {
          #if compiler(>=6.2)
          recordAttachment(
            writeToDisk ? try Data(contentsOf: snapshotFileUrl) : snapshotData,
            named: snapshotFileUrl.lastPathComponent,
            sourceLocation: SourceLocation(
              fileID: fileID.description,
              filePath: filePath.description,
              line: Int(line),
              column: Int(column)
            )
          )
          #endif
        }
        #endif
      }

      if record == .all {
        try await recordSnapshot(writeToDisk: true)

        return """
          Record mode is on. Automatically recorded snapshot: …

          open "\(snapshotFileUrl.absoluteString)"

          Turn record mode off and re-run "\(testName)" to assert against the newly-recorded snapshot
          """
      }

      guard fileManager.fileExists(atPath: snapshotFileUrl.path) else {
        if record == .never {
          try await recordSnapshot(writeToDisk: false)

          return """
            No reference was found on disk. New snapshot was not recorded because recording is disabled
            """
        } else {
          try await recordSnapshot(writeToDisk: true)

          return """
            No reference was found on disk. Automatically recorded snapshot: …

            open "\(snapshotFileUrl.absoluteString)"

            Re-run "\(testName)" to assert against the newly-recorded snapshot.
            """
        }
      }

      let data = try Data(contentsOf: snapshotFileUrl)
      let reference: Format
      do {
        reference = try snapshotting.serializer.fromData(data)
      } catch {
        return """
          Couldn't load reference snapshot: \(error.localizedDescription)

          The reference file may be corrupt. Delete it and re-run the test to record a new one:

          open "\(snapshotFileUrl.absoluteString)"
          """
      }

      guard let failure = try snapshotting.comparator.diff(reference, diffable) else {
        return nil
      }
      let artifacts = failure.artifacts

      let artifactsUrl = URL(
        fileURLWithPath: ProcessInfo.processInfo.environment["SNAPSHOT_ARTIFACTS"]
          ?? NSTemporaryDirectory(),
        isDirectory: true
      )
      let artifactsSubUrl = artifactsUrl.appendingPathComponent(fileName)
      try fileManager.createDirectory(at: artifactsSubUrl, withIntermediateDirectories: true)
      let failedSnapshotFileUrl = artifactsSubUrl.appendingPathComponent(
        snapshotFileUrl.lastPathComponent
      )
      try snapshotting.serializer.toData(diffable).write(to: failedSnapshotFileUrl)

      if !artifacts.isEmpty {
        #if !os(Linux) && !os(Android) && !os(Windows)
        if ProcessInfo.processInfo.environment.keys.contains("__XCODE_BUILT_PRODUCTS_DIR_PATHS") {
          #if compiler(>=6.2)
          for artifact in artifacts {
            recordAttachment(
              artifact.data,
              named: artifact.name,
              sourceLocation: SourceLocation(
                fileID: fileID.description,
                filePath: filePath.description,
                line: Int(line),
                column: Int(column)
              )
            )
          }
          #endif
        }
        #endif
      }

      let diffMessage = (SnapshotTestingConfiguration.current?.diffTool ?? _diffTool)(
        currentFilePath: snapshotFileUrl.path,
        failedFilePath: failedSnapshotFileUrl.path
      )

      // The first line is the only line Xcode shows in the issue navigator, so it must carry the
      // specific reason. Everything below it is ordered by decreasing usefulness: failure detail,
      // then file URLs / diff tool command.
      var failureMessage: String
      if let name {
        failureMessage = "[\(name)] \(failure.reason)"
      } else {
        failureMessage = failure.reason
      }

      if record == .failed {
        try await recordSnapshot(writeToDisk: true)
        failureMessage += " A new snapshot was automatically recorded."
      }

      if let detail = failure.detail?.trimmingCharacters(in: .whitespacesAndNewlines),
        !detail.isEmpty
      {
        failureMessage += "\n\n\(detail)"
      }

      return """
        \(failureMessage)

        \(diffMessage)
        """
    } catch {
      return "Snapshot test failed: \(error.localizedDescription)"
    }
  }
}

// MARK: - Private

private var counter: File.Counter {
  #if canImport(Testing)
  if Test.current != nil {
    return File.counter
  } else {
    return _counter
  }
  #else
  return _counter
  #endif
}

private let _counter = File.Counter()

func sanitizePathComponent(_ string: String) -> String {

  string
    .replacingOccurrences(of: "\\W+", with: "-", options: .regularExpression)
    .replacingOccurrences(of: "^-|-$", with: "", options: .regularExpression)
}

#if !os(Android) && !os(Linux) && !os(Windows)
import UniformTypeIdentifiers

func uniformTypeIdentifier(fromExtension pathExtension: String) -> String? {
  UTType(filenameExtension: pathExtension)?.identifier
}
#endif

enum File {
  @TaskLocal static var counter = Counter()

  final class Counter: Sendable {
    private let counts = Mutex<[String: Int]>([:])

    init() {}

    func next(for key: String) -> Int {
      counts.withLock {
        $0[key, default: 0] += 1
        return $0[key]!
      }
    }

    func reset() {
      counts.withLock { $0.removeAll() }
    }
  }
}

private func recordAttachment(
  _ data: Data,
  named name: String,
  sourceLocation: SourceLocation
) {
  #if !os(Android) && !os(Linux) && !os(Windows)
  #if compiler(>=6.3) && (canImport(UIKit) || canImport(AppKit))
  if name.hasSuffix(".png"),
    let image = XImage(data: data)
  {
    Attachment.record(image, named: name, as: .png, sourceLocation: sourceLocation)
    return
  }
  #endif
  Attachment.record(data, named: name, sourceLocation: sourceLocation)
  #endif
}
