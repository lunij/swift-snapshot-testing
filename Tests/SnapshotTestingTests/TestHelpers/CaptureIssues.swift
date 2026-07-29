import Synchronization
import Testing

@testable import SnapshotTesting

/// A failure an assertion reported, captured rather than recorded.
struct CapturedIssue {
  let message: String
  let sourceLocation: SourceLocation
}

/// Collects the failures `operation` reports instead of letting them fail the current test.
///
/// Assertions report through ``IssueReporter``, so a test can assert on what an assertion *says*
/// without asserting on Swift Testing's own handling of it.
func captureIssues(
  isolation: isolated (any Actor)? = #isolation,
  _ operation: () async throws -> Void
) async rethrows -> [CapturedIssue] {
  let captured = Mutex<[CapturedIssue]>([])
  let reporter = IssueReporter { message, sourceLocation in
    captured.withLock {
      $0.append(CapturedIssue(message: message, sourceLocation: sourceLocation))
    }
  }
  try await IssueReporter.$current.withValue(reporter) {
    try await operation()
  }
  return captured.withLock { $0 }
}
