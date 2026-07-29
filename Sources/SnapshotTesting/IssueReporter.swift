import Testing

/// Where a snapshot failure is reported.
///
/// Substituting a reporter lets a caller observe the failures an assertion produces instead of
/// failing the run with them.
struct IssueReporter: Sendable {
  /// Reports a single failure.
  let report: @Sendable (_ message: String, _ sourceLocation: SourceLocation) -> Void

  /// Records the failure as a Swift Testing issue, failing the current test.
  static let issue = IssueReporter { message, sourceLocation in
    Issue.record(Comment(rawValue: message), sourceLocation: sourceLocation)
  }

  /// The reporter in effect for the current task.
  @TaskLocal static var current: IssueReporter = .issue
}

public func reportIssue(
  _ message: @autoclosure () -> String,
  fileID: StaticString,
  filePath: StaticString,
  line: UInt,
  column: UInt
) {
  IssueReporter.current.report(
    message(),
    SourceLocation(
      fileID: fileID.description,
      filePath: filePath.description,
      line: Int(line),
      column: Int(column)
    )
  )
}
