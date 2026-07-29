import Testing

/// A trait that configures snapshotting for a suite or test.
///
/// Each trait carries a single value; a value it leaves unspecified is inherited from the enclosing
/// scope, so traits applied side by side combine.
@_documentation(visibility: internal)
public struct SnapshotConfigurationTrait: SuiteTrait, TestTrait {
  public let isRecursive = true

  /// The record mode to apply, or `nil` to inherit it from the enclosing scope.
  let record: SnapshotConfiguration.Record?

  /// The diff tool to apply, or `nil` to inherit it from the enclosing scope.
  let diffTool: SnapshotConfiguration.DiffTool?
}

extension Trait where Self == SnapshotConfigurationTrait {
  /// Sets the record mode of a suite or test.
  ///
  /// ```swift
  /// @Suite(.snapshotRecord(.failed))
  /// struct FeatureTests {}
  /// ```
  ///
  /// - Parameter record: The recording strategy to use while taking snapshots.
  public static func snapshotRecord(_ record: SnapshotConfiguration.Record) -> Self {
    SnapshotConfigurationTrait(record: record, diffTool: nil)
  }

  /// Sets the diff tool of a suite or test.
  ///
  /// ```swift
  /// @Suite(.snapshotDiffTool(.ksdiff))
  /// struct FeatureTests {}
  /// ```
  ///
  /// - Parameter diffTool: The diff tool to use in failure messages.
  public static func snapshotDiffTool(_ diffTool: SnapshotConfiguration.DiffTool) -> Self {
    SnapshotConfigurationTrait(record: nil, diffTool: diffTool)
  }
}

extension SnapshotConfigurationTrait: TestScoping {
  public func provideScope(
    for test: Test,
    testCase: Test.Case?,
    performing function: () async throws -> Void
  ) async throws {
    try await withSnapshotConfiguration(record: record, diffTool: diffTool) {
      try await File.$counter.withValue(File.Counter()) {
        try await function()
      }
    }
  }
}
