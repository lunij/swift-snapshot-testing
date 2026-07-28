import Snapshotting
import Testing

/// Compares a value against a reference snapshot on disk, failing the current test on a mismatch.
///
/// - Parameters:
///   - value: A value to compare against a reference.
///   - strategy: A strategy for serializing, deserializing, and comparing values.
///   - name: An optional suffix distinguishing several snapshots taken by the same test, appended to
///     `testName`. There is no counter, so snapshots a test takes in the same format need names.
///   - record: The record mode to use. Defaults to `.failed`, which re-records a mismatch so that an
///     intended change can be reviewed as a diff of the reference file.
///   - testName: The test the snapshot was taken in, which names the reference file.
func expectSnapshot<Value, Format>(
  of value: @autoclosure () throws -> Value,
  as strategy: SnapshotStrategy<Value, Format>,
  named name: String? = nil,
  record: SnapshotConfiguration.Record = .failed,
  testName: String = #function,
  sourceLocation: SourceLocation = #_sourceLocation,
  isolation: isolated (any Actor)? = #isolation
) async {
  var fileName = sanitizePathComponent(testName)
  if let name {
    fileName += ".\(sanitizePathComponent(name))"
  }
  if let pathExtension = strategy.pathExtension {
    fileName += ".\(pathExtension)"
  }
  let file = SnapshotFile(fileName, filePath: sourceLocation.filePath)

  let result = await compareSnapshot(
    of: try value(),
    as: strategy,
    against: file.snapshotURL,
    artifactDirectory: file.artifactDirectory,
    record: record,
    isolation: isolation
  )

  if let failure = result.failure {
    Issue.record(Comment(rawValue: failure), sourceLocation: sourceLocation)
  }
}

/// Reduces a test or snapshot name to something usable as a file name, turning `#function`'s
/// `"Encodable snapshot()"` into `"Encodable-snapshot"`.
private func sanitizePathComponent(_ string: String) -> String {
  string
    .replacingOccurrences(of: "\\W+", with: "-", options: .regularExpression)
    .replacingOccurrences(of: "^-|-$", with: "", options: .regularExpression)
}
