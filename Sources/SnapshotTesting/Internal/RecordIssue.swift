import Testing

@_spi(Internals)
public func recordIssue(
  _ message: @autoclosure () -> String,
  fileID: StaticString,
  filePath: StaticString,
  line: UInt,
  column: UInt
) {
  Issue.record(
    Comment(rawValue: message()),
    sourceLocation: SourceLocation(
      fileID: fileID.description,
      filePath: filePath.description,
      line: Int(line),
      column: Int(column)
    )
  )
}
