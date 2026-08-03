import Foundation
// The effective record mode has to be known before comparing, to decide whether two snapshots may
// share a reference.
@_spi(Internals) import Snapshotting
import Testing

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Asserts that a given value matches a reference on disk.
///
/// The reference is named after the test, after what `strategy` renders, and — on a platform whose
/// rendering differs — after the platform, which is derived rather than passed in. Pass `suffixed:`
/// only for what none of those can supply, such as telling two snapshots of one test apart.
///
/// Two snapshots of one test that resolve to the same name are reported rather than allowed to
/// overwrite each other, unless neither of them records, in which case they may share the reference
/// they both read.
///
/// - Parameters:
///   - value: A value to compare against a reference.
///   - strategy: A strategy for serializing, deserializing, and comparing values.
///   - suffix: An optional suffix distinguishing several snapshots taken by the same test.
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
  suffixed suffix: String? = nil,
  record: SnapshotConfiguration.Record? = nil,
  isolation: isolated (any Actor)? = #isolation,
  fileID: StaticString = #fileID,
  file filePath: StaticString = #filePath,
  testName: String = #function,
  line: UInt = #line,
  column: UInt = #column
) async {
  let record = record ?? SnapshotConfiguration.current.record
  let location = SnapshotLocation(
    identifier: strategy.identifier,
    suffixed: suffix,
    pathExtension: strategy.pathExtension,
    snapshotDirectory: nil,
    filePath: filePath,
    testName: testName
  )

  // Comparing would pit this snapshot against whatever the earlier one recorded, and then overwrite
  // it, so the snapshot is not taken at all.
  let willRecord = record.records(whenReferenceExists: location.referenceExists)
  if Register.current.claim(location.snapshotURL, recording: willRecord) {
    reportIssue(
      """
      Two snapshots in this test resolve to '\(location.snapshotURL.lastPathComponent)', and one of \
      them records to it, so the second would be compared against whatever the first recorded. Give \
      them different names.
      """,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
    return
  }

  let result = await compareSnapshot(
    of: try value(),
    as: strategy,
    against: location.snapshotURL,
    artifactDirectory: location.artifactDirectory,
    named: suffix,
    record: record,
    isolation: isolation
  )
  recordAttachments(
    result.artifacts,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column
  )
  guard var message = result.failureMessage else { return }
  if let hint = sharedReferenceHint(for: result, at: location) {
    message += "\n\n\(hint)"
  }
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
///   - strategies: A dictionary of suffixes and strategies for serializing, deserializing, and
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
  for (suffix, strategy) in strategies {
    await assertSnapshot(
      of: try value(),
      as: strategy,
      suffixed: suffix,
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
/// Each strategy names its own reference, so the strategies have to be distinguishable: two that
/// render the same format need the dictionary overload, which suffixes them.
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
/// `verifySnapshot` with your own arguments, and then report an issue with the returned failure
/// message if it is non-`nil`.
///
/// Unlike `assertSnapshot`, this hands back a comparison rather than making an assertion, so it does
/// not refuse a name an earlier snapshot in the same test already used: comparing one reference
/// against several values in turn is a legitimate thing to ask a comparison for.
///
/// For example, if you want the snapshot directory to be determined by an environment variable, you
/// can create your own assert helper like so:
///
/// ```swift
/// public func myAssertSnapshot<Value, Format>(
///   of value: @autoclosure () throws -> Value,
///   as strategy: SnapshotStrategy<Value, Format>,
///   suffixed suffix: String? = nil,
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
///       suffixed: suffix,
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
///   - suffix: An optional suffix distinguishing several snapshots taken by the same test.
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
  suffixed suffix: String? = nil,
  record: SnapshotConfiguration.Record? = nil,
  snapshotDirectory: String? = nil,
  isolation: isolated (any Actor)? = #isolation,
  file filePath: StaticString = #filePath,
  testName: String = #function
) async -> SnapshotResult {
  let location = SnapshotLocation(
    identifier: strategy.identifier,
    suffixed: suffix,
    pathExtension: strategy.pathExtension,
    snapshotDirectory: snapshotDirectory,
    filePath: filePath,
    testName: testName
  )

  return await compareSnapshot(
    of: try value(),
    as: strategy,
    against: location.snapshotURL,
    artifactDirectory: location.artifactDirectory,
    named: suffix,
    record: record,
    isolation: isolation
  )
}

// MARK: - Private

/// Points out that a mismatching reference is shared by every platform.
///
/// Two platforms rarely render a value identically, so a shared reference that stops matching is as
/// likely to be a reference recorded elsewhere as it is a change in the value.
private func sharedReferenceHint(
  for result: SnapshotResult,
  at location: SnapshotLocation
) -> String? {
  guard
    case .mismatched = result.outcome,
    let platformSpecificName = location.platformSpecificName
  else { return nil }

  return """
    '\(location.snapshotURL.lastPathComponent)' is shared by every platform. If it differs because of \
    the platform this ran on, rename it after the platform that recorded it — this run then records \
    '\(platformSpecificName)'.
    """
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
