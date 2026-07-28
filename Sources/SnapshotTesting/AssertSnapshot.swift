import Foundation
@_spi(Internals) import Snapshotting

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

#if canImport(Testing)
import Testing
#endif

/// Asserts that a given value matches a reference on disk.
///
/// - Parameters:
///   - value: A value to compare against a reference.
///   - strategy: A strategy for serializing, deserializing, and comparing values.
///   - name: An optional description of the snapshot.
///   - record: The record mode to use while asserting snapshots.
///   - isolation: The actor to isolate to.
///   - fileID: The file ID in which failure occurred. Defaults to the file ID of the test case in
///     which this function was called.
///   - filePath: The file in which failure occurred. Defaults to the file path of the test case in
///     which this function was called.
///   - testName: The name of the test in which failure occurred. Defaults to the function name of
///     the test case in which this function was called.
///   - line: The line number on which failure occurred. Defaults to the line number on which this
///     function was called.
///   - column: The column on which failure occurred. Defaults to the column on which this function
///     was called.
public func assertSnapshot<Value, Format>(
  of value: @autoclosure () throws -> Value,
  as strategy: SnapshotStrategy<Value, Format>,
  named name: String? = nil,
  record: SnapshotConfiguration.Record? = nil,
  isolation: isolated (any Actor)? = #isolation,
  fileID: StaticString = #fileID,
  file filePath: StaticString = #filePath,
  testName: String = #function,
  line: UInt = #line,
  column: UInt = #column
) async {
  let failure = await verifySnapshot(
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
///   - record: The record mode to use while asserting snapshots.
///   - isolation: The actor to isolate to.
///   - fileID: The file ID in which failure occurred. Defaults to the file ID of the test case in
///     which this function was called.
///   - filePath: The file in which failure occurred. Defaults to the file path of the test case in
///     which this function was called.
///   - testName: The name of the test in which failure occurred. Defaults to the function name of
///     the test case in which this function was called.
///   - line: The line number on which failure occurred. Defaults to the line number on which this
///     function was called.
///   - column: The column on which failure occurred. Defaults to the column on which this function
///     was called.
public func assertSnapshots<Value, Format>(
  of value: @autoclosure () throws -> Value,
  as strategies: [String: SnapshotStrategy<Value, Format>],
  record: SnapshotConfiguration.Record? = nil,
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
///   - isolation: The actor to isolate to.
///   - fileID: The file ID in which failure occurred. Defaults to the file ID of the test case in
///     which this function was called.
///   - filePath: The file in which failure occurred. Defaults to the file path of the test case in
///     which this function was called.
///   - testName: The name of the test in which failure occurred. Defaults to the function name of
///     the test case in which this function was called.
///   - line: The line number on which failure occurred. Defaults to the line number on which this
///     function was called.
///   - column: The column on which failure occurred. Defaults to the column on which this function
///     was called.
public func assertSnapshots<Value, Format>(
  of value: @autoclosure () throws -> Value,
  as strategies: [SnapshotStrategy<Value, Format>],
  record: SnapshotConfiguration.Record? = nil,
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
///   as strategy: SnapshotStrategy<Value, Format>,
///   named name: String? = nil,
///   record: SnapshotConfiguration.Record? = nil,
///   file: StaticString = #file,
///   testName: String = #function,
///   line: UInt = #line
///   ) async {
///
///     let snapshotDirectory = ProcessInfo.processInfo.environment["SNAPSHOT_REFERENCE_DIR"]! + "/" + #file
///     let failure = await verifySnapshot(
///       of: try value(),
///       as: strategy,
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
///   - strategy: A strategy for serializing, deserializing, and comparing values.
///   - name: An optional description of the snapshot.
///   - record: The record mode to use while asserting snapshots.
///   - snapshotDirectory: Optional directory to save snapshots. By default snapshots will be saved
///     in a directory with the same name as the test file, and that directory will sit inside a
///     directory `__Snapshots__` that sits next to your test file.
///   - isolation: The actor to isolate to.
///   - fileID: The file ID in which failure occurred. Defaults to the file ID of the test case in
///     which this function was called.
///   - filePath: The file in which failure occurred. Defaults to the file path of the test case in
///     which this function was called.
///   - testName: The name of the test in which failure occurred. Defaults to the function name of
///     the test case in which this function was called.
///   - line: The line number on which failure occurred. Defaults to the line number on which this
///     function was called.
///   - column: The column on which failure occurred. Defaults to the column on which this function
///     was called.
/// - Returns: A failure message or, if the value matches, nil.
public func verifySnapshot<Value, Format>(
  of value: @autoclosure () throws -> Value,
  as strategy: SnapshotStrategy<Value, Format>,
  named name: String? = nil,
  record: SnapshotConfiguration.Record? = nil,
  snapshotDirectory: String? = nil,
  isolation: isolated (any Actor)? = #isolation,
  fileID: StaticString = #fileID,
  file filePath: StaticString = #filePath,
  testName: String = #function,
  line: UInt = #line,
  column: UInt = #column
) async -> String? {
  let record = record ?? SnapshotConfiguration.current?.record ?? _record
  return await withSnapshotConfiguration(record: record, isolation: isolation) { () async -> String? in
    do {
      let location = SnapshotLocation(
        named: name,
        pathExtension: strategy.pathExtension,
        snapshotDirectory: snapshotDirectory,
        filePath: filePath,
        testName: testName
      )
      let snapshotURL = location.snapshotURL

      let fileManager = FileManager.default
      try fileManager.createDirectory(
        at: snapshotURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
      )

      let snapshotValue = try value()
      let diffable = await strategy.snapshot(snapshotValue)

      func recordSnapshot(writeToDisk: Bool) async throws {
        let snapshotData = try strategy.serializer.toData(diffable)

        if writeToDisk {
          try snapshotData.write(to: snapshotURL)
        }

        #if !os(Android) && !os(Linux) && !os(Windows)
        if ProcessInfo.processInfo.environment.keys.contains("__XCODE_BUILT_PRODUCTS_DIR_PATHS") {
          #if compiler(>=6.2)
          recordAttachment(
            writeToDisk ? try Data(contentsOf: snapshotURL) : snapshotData,
            named: snapshotURL.lastPathComponent,
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

          open "\(snapshotURL.absoluteString)"

          Turn record mode off and re-run "\(location.testName)" to assert against the newly-recorded snapshot
          """
      }

      guard fileManager.fileExists(atPath: snapshotURL.path) else {
        if record == .never {
          try await recordSnapshot(writeToDisk: false)

          return """
            No reference was found on disk. New snapshot was not recorded because recording is disabled
            """
        } else {
          try await recordSnapshot(writeToDisk: true)

          return """
            No reference was found on disk. Automatically recorded snapshot: …

            open "\(snapshotURL.absoluteString)"

            Re-run "\(location.testName)" to assert against the newly-recorded snapshot.
            """
        }
      }

      let data = try Data(contentsOf: snapshotURL)
      let reference: Format
      do {
        reference = try strategy.serializer.fromData(data)
      } catch {
        return """
          Couldn't load reference snapshot: \(error.localizedDescription)

          The reference file may be corrupt. Delete it and re-run the test to record a new one:

          open "\(snapshotURL.absoluteString)"
          """
      }

      guard let failure = try strategy.comparator.diff(reference, diffable) else {
        return nil
      }
      let artifacts = failure.artifacts

      try fileManager.createDirectory(
        at: location.artifactDirectory,
        withIntermediateDirectories: true
      )
      let failedSnapshotURL = location.artifactDirectory.appendingPathComponent(
        snapshotURL.lastPathComponent
      )
      try strategy.serializer.toData(diffable).write(to: failedSnapshotURL)

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

      let diffMessage = (SnapshotConfiguration.current?.diffTool ?? _diffTool)(
        currentFilePath: snapshotURL.path,
        failedFilePath: failedSnapshotURL.path
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

#if !os(Android) && !os(Linux) && !os(Windows)
import UniformTypeIdentifiers

func uniformTypeIdentifier(fromExtension pathExtension: String) -> String? {
  UTType(filenameExtension: pathExtension)?.identifier
}
#endif

private func recordAttachment(
  _ data: Data,
  named name: String,
  sourceLocation: SourceLocation
) {
  #if !os(Android) && !os(Linux) && !os(Windows)
  #if compiler(>=6.3) && (canImport(UIKit) || canImport(AppKit))
  if name.hasSuffix(".png") {
    #if os(macOS)
    let image = NSImage(data: data)
    #elseif os(iOS) || os(tvOS) || os(visionOS)
    let image = UIImage(data: data)
    #else
    let image: Never? = nil
    #endif
    if let image {
      Attachment.record(image, named: name, as: .png, sourceLocation: sourceLocation)
      return
    }
  }
  #endif
  Attachment.record(data, named: name, sourceLocation: sourceLocation)
  #endif
}
