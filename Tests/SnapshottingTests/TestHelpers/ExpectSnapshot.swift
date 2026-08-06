import Foundation
import Snapshotting
import Testing

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Compares a value against a reference snapshot on disk, failing the current test on a mismatch.
///
/// A mismatch also attaches what was rendered to the test report, so the failure can be inspected
/// from the `.xcresult` alone.
///
/// Use ``snapshotResult(of:as:suffixed:record:testName:filePath:isolation:)`` instead when the
/// failure itself is what a test is asserting on.
///
/// - Parameters:
///   - value: A value to compare against a reference.
///   - strategy: A strategy for serializing, deserializing, and comparing values.
///   - suffix: An optional suffix distinguishing several snapshots taken by the same test, appended to the derived name.
///   - record: The record mode to use. Defaults to `.failed`, which re-records a mismatch so that an
///     intended change can be reviewed as a diff of the reference file.
///   - testName: The test the snapshot was taken in, which names the reference file.
func expectSnapshot<Value, Format>(
  of value: @autoclosure () throws -> Value,
  as strategy: SnapshotStrategy<Value, Format>,
  suffixed suffix: String? = nil,
  record: SnapshotConfiguration.Record = .failed,
  testName: String = #function,
  sourceLocation: SourceLocation = #_sourceLocation,
  isolation: isolated (any Actor)? = #isolation
) async {
  let result = await snapshotResult(
    of: try value(),
    as: strategy,
    suffixed: suffix,
    record: record,
    testName: testName,
    filePath: sourceLocation.filePath,
    isolation: isolation
  )

  recordAttachments(result.artifacts, sourceLocation: sourceLocation)

  if let failure = result.failureMessage {
    Issue.record(Comment(rawValue: failure), sourceLocation: sourceLocation)
  }
}

/// Compares a value against a reference snapshot on disk and hands back the outcome, reporting
/// nothing.
///
/// This exists for the tests that assert on failure *messages* — recording an issue would fail the
/// very test that is checking the engine reports a mismatch correctly. It applies the same file
/// naming as ``expectSnapshot(of:as:suffixed:record:testName:sourceLocation:isolation:)``.
func snapshotResult<Value, Format>(
  of value: @autoclosure () throws -> Value,
  as strategy: SnapshotStrategy<Value, Format>,
  suffixed suffix: String? = nil,
  record: SnapshotConfiguration.Record = .failed,
  testName: String = #function,
  filePath: String = #filePath,
  isolation: isolated (any Actor)? = #isolation
) async -> SnapshotResult {
  var stem = sanitizePathComponent(testName)
  if let identifier = strategy.identifier {
    stem += ".\(sanitizePathComponent(identifier))"
  }
  if let suffix {
    stem += ".\(sanitizePathComponent(suffix))"
  }
  let file = SnapshotFile(
    stem: stem,
    pathExtension: strategy.pathExtension,
    filePath: filePath
  )

  return await compareSnapshot(
    of: try value(),
    as: strategy,
    against: file.snapshotURL,
    artifactDirectory: file.artifactDirectory,
    named: suffix,
    record: record,
    isolation: isolation
  )
}

extension SnapshotResult.Outcome {
  /// The comparator's failure, or `nil` if the value matched or never reached comparison.
  ///
  /// Lets a test assert on the reason alone, without spelling out the detail and artifacts that
  /// come with a whole `SnapshotFailure`.
  var mismatch: SnapshotFailure? {
    guard case .mismatched(let failure) = self else { return nil }
    return failure
  }
}

/// Records snapshot artifacts as test attachments, so that a mismatch on a machine you cannot reach
/// — a CI runner — arrives with the image that failed rather than only the message describing it.
///
/// Attachments are only captured when the run is hosted by Xcode, which is what puts them in the
/// resulting `.xcresult`. Recording them elsewhere would discard them.
private func recordAttachments(_ artifacts: [SnapshotArtifact], sourceLocation: SourceLocation) {
  #if !os(Linux) && !os(Windows)
  #if compiler(>=6.2)
  guard
    !artifacts.isEmpty,
    ProcessInfo.processInfo.environment.keys.contains("__XCODE_BUILT_PRODUCTS_DIR_PATHS")
  else { return }

  for artifact in artifacts {
    recordAttachment(artifact.data, named: artifact.name, sourceLocation: sourceLocation)
  }
  #endif
  #endif
}

/// Attaches a blob, preferring the image overload so that a PNG can be previewed in the test report
/// instead of downloaded as bytes.
private func recordAttachment(_ data: Data, named name: String, sourceLocation: SourceLocation) {
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

/// Reduces a test name or a suffix to something usable as a file name, turning `#function`'s
/// `"Encodable snapshot()"` into `"Encodable-snapshot"`.
private func sanitizePathComponent(_ string: String) -> String {
  string
    .replacingOccurrences(of: "\\W+", with: "-", options: .regularExpression)
    .replacingOccurrences(of: "^-|-$", with: "", options: .regularExpression)
}
