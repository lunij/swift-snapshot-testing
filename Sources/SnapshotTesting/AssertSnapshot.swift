import Foundation
import Snapshotting
import Synchronization
import Testing

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Asserts that a given value matches a reference on disk.
///
/// - Parameters:
///   - value: A value to compare against a reference.
///   - strategy: A strategy for serializing, deserializing, and comparing values.
///   - name: An optional description of the snapshot.
///   - argument: The argument the test case is running under. Only a parameterized test has one, and
///     only there does it take part in the file name, so that the cases of one test do not share a
///     reference.
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
  argument: (any LosslessStringConvertible)? = nil,
  record: SnapshotConfiguration.Record? = nil,
  isolation: isolated (any Actor)? = #isolation,
  fileID: StaticString = #fileID,
  file filePath: StaticString = #filePath,
  testName: String = #function,
  line: UInt = #line,
  column: UInt = #column
) async {
  reportProcessRecordWarningOnce(
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column
  )
  let result = await verifySnapshot(
    of: try value(),
    as: strategy,
    named: name,
    argument: argument,
    record: record,
    isolation: isolation,
    file: filePath,
    testName: testName
  )
  recordAttachments(
    result.artifacts,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column
  )
  guard let message = result.failureMessage else { return }
  reportIssue(
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
///   - argument: The argument the test case is running under. Only a parameterized test has one, and
///     only there does it take part in the file name, so that the cases of one test do not share a
///     reference.
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
  argument: (any LosslessStringConvertible)? = nil,
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
      argument: argument,
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
///   - argument: The argument the test case is running under. Only a parameterized test has one, and
///     only there does it take part in the file name, so that the cases of one test do not share a
///     reference.
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
  argument: (any LosslessStringConvertible)? = nil,
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
      argument: argument,
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
/// `verifySnapshot` with your own arguments, and then report an issue with the returned failure
/// message if it is non-`nil`. For example, if you want the snapshot directory to be determined by
/// an environment variable, you can create your own assert helper like so:
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
///     let result = await verifySnapshot(
///       of: try value(),
///       as: strategy,
///       named: name,
///       record: record,
///       snapshotDirectory: snapshotDirectory,
///       file: file,
///       testName: testName
///     )
///     guard let message = result.failureMessage else { return }
///     Issue.record(Comment(rawValue: message))
/// }
/// ```
///
/// - Parameters:
///   - value: A value to compare against a reference.
///   - strategy: A strategy for serializing, deserializing, and comparing values.
///   - name: An optional description of the snapshot.
///   - argument: The argument the test case is running under. Only a parameterized test has one, and
///     only there does it take part in the file name, so that the cases of one test do not share a
///     reference.
///   - record: The record mode to use while asserting snapshots.
///   - snapshotDirectory: Optional directory to save snapshots. By default snapshots will be saved
///     in a directory with the same name as the test file, and that directory will sit inside a
///     directory `__Snapshots__` that sits next to your test file.
///   - isolation: The actor to isolate to.
///   - filePath: The file the snapshot directory is derived from. Defaults to the file path of the
///     test case in which this function was called.
///   - testName: The name of the test the snapshot is named after. Defaults to the function name of
///     the test case in which this function was called.
/// - Returns: The result of the comparison, carrying a failure message if the value did not match
///   its reference, along with any artifacts worth attaching to the failure.
public func verifySnapshot<Value, Format>(
  of value: @autoclosure () throws -> Value,
  as strategy: SnapshotStrategy<Value, Format>,
  named name: String? = nil,
  argument: (any LosslessStringConvertible)? = nil,
  record: SnapshotConfiguration.Record? = nil,
  snapshotDirectory: String? = nil,
  isolation: isolated (any Actor)? = #isolation,
  file filePath: StaticString = #filePath,
  testName: String = #function
) async -> SnapshotResult {
  let location = SnapshotLocation(
    named: name,
    argument: argument,
    pathExtension: strategy.pathExtension,
    snapshotDirectory: snapshotDirectory,
    filePath: filePath,
    testName: testName
  )
  // Returned rather than reported, so that the refusal reaches whoever called this — a third-party
  // assert helper included — through the result they already inspect. The value is left unevaluated:
  // a snapshot that cannot be identified is not taken.
  if let refusal = location.refusal {
    return SnapshotResult(
      outcome: .errored(refusal),
      snapshotURL: location.snapshotURL,
      name: name
    )
  }
  return await compareSnapshot(
    of: try value(),
    as: strategy,
    against: location.snapshotURL,
    artifactDirectory: location.artifactDirectory,
    named: name,
    record: record,
    isolation: isolation
  )
}

// MARK: - Private

/// Whether the process-wide record mode misconfiguration has already been reported.
private let hasReportedProcessRecordWarning = Mutex(false)

/// Reports a malformed `SNAPSHOT_RECORD` the first time an assertion runs.
///
/// The misconfiguration is process-wide, so it is reported once and lands on whichever assertion
/// happened to run first rather than on all of them.
private func reportProcessRecordWarningOnce(
  fileID: StaticString,
  filePath: StaticString,
  line: UInt,
  column: UInt
) {
  guard let warning = ProcessRecord.current.warning else { return }
  let isFirst = hasReportedProcessRecordWarning.withLock { hasReported in
    defer { hasReported = true }
    return !hasReported
  }
  guard isFirst else { return }
  reportIssue(warning, fileID: fileID, filePath: filePath, line: line, column: column)
}

/// Records snapshot artifacts as test attachments, so that they show up alongside the failure in
/// Xcode's test report.
private func recordAttachments(
  _ artifacts: [SnapshotArtifact],
  fileID: StaticString,
  filePath: StaticString,
  line: UInt,
  column: UInt
) {
  #if !os(Linux) && !os(Windows)
  #if compiler(>=6.2)
  guard
    !artifacts.isEmpty,
    ProcessInfo.processInfo.environment.keys.contains("__XCODE_BUILT_PRODUCTS_DIR_PATHS")
  else { return }

  let sourceLocation = SourceLocation(
    fileID: fileID.description,
    filePath: filePath.description,
    line: Int(line),
    column: Int(column)
  )
  for artifact in artifacts {
    recordAttachment(artifact.data, named: artifact.name, sourceLocation: sourceLocation)
  }
  #endif
  #endif
}

private func recordAttachment(
  _ data: Data,
  named name: String,
  sourceLocation: SourceLocation
) {
  #if !os(Linux) && !os(Windows)
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
