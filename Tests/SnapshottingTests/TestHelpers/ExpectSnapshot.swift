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
/// Use ``snapshotResult(of:as:named:record:testName:filePath:isolation:)`` instead when the failure
/// itself is what a test is asserting on.
///
/// - Parameters:
///   - value: A value to compare against a reference.
///   - strategy: A strategy for serializing, deserializing, and comparing values.
///   - name: An optional suffix distinguishing several snapshots taken by the same test, appended to
///     `testName`. There is no counter, so snapshots a test takes in the same format need names.
///   - record: The record mode to use, or `nil` to take the one the process resolved: `.failed`
///     locally, so that an intended change can be reviewed as a diff of the reference file, and
///     `.never` on a runner, where a recorded reference is discarded with the checkout.
///   - testName: The test the snapshot was taken in, which names the reference file.
func expectSnapshot<Value, Format>(
  of value: @autoclosure () throws -> Value,
  as strategy: SnapshotStrategy<Value, Format>,
  named name: String? = nil,
  record: SnapshotConfiguration.Record? = nil,
  testName: String = #function,
  sourceLocation: SourceLocation = #_sourceLocation,
  isolation: isolated (any Actor)? = #isolation
) async {
  let result = await snapshotResult(
    of: try value(),
    as: strategy,
    named: name,
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
/// naming as ``expectSnapshot(of:as:named:record:testName:sourceLocation:isolation:)``.
func snapshotResult<Value, Format>(
  of value: @autoclosure () throws -> Value,
  as strategy: SnapshotStrategy<Value, Format>,
  named name: String? = nil,
  record: SnapshotConfiguration.Record? = nil,
  testName: String = #function,
  filePath: String = #filePath,
  isolation: isolated (any Actor)? = #isolation
) async -> SnapshotResult {
  let file = SnapshotFile(
    base: testName,
    qualifiers: [name].compactMap { $0 },
    pathExtension: strategy.pathExtension,
    filePath: filePath
  )

  return await compareSnapshot(
    of: try value(),
    as: strategy,
    against: file.reference.url,
    artifactDirectory: file.artifactDirectory,
    named: name,
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
