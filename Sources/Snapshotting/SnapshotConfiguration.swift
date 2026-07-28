import Foundation
import Synchronization

/// Customizes snapshotting for the duration of an operation.
///
/// Use this operation to customize how snapshots are recorded, and how failures are reported, for a
/// scoped region of code. The configuration is stored in a task local, so it applies to every
/// snapshot taken within `operation`, including nested ones.
///
/// > Note: When using Swift's native Testing library, prefer the `snapshots(record:diffTool:)`
/// > trait, which applies a configuration to a whole test or suite.
///
/// - Parameters:
///   - record: The record mode to use while asserting snapshots.
///   - diffTool: The diff tool to use while asserting snapshots.
///   - operation: The operation to perform.
public func withSnapshotConfiguration<R>(
  record: SnapshotConfiguration.Record? = nil,
  diffTool: SnapshotConfiguration.DiffTool? = nil,
  operation: () throws -> R
) rethrows -> R {
  try SnapshotConfiguration.$current.withValue(
    SnapshotConfiguration(
      record: record ?? SnapshotConfiguration.current?.record ?? _record,
      diffTool: diffTool ?? SnapshotConfiguration.current?.diffTool ?? _diffTool
    )
  ) {
    try operation()
  }
}

/// Customizes snapshotting for the duration of an asynchronous operation.
///
/// See ``withSnapshotConfiguration(record:diffTool:operation:)`` for more information.
public func withSnapshotConfiguration<R>(
  record: SnapshotConfiguration.Record? = nil,
  diffTool: SnapshotConfiguration.DiffTool? = nil,
  isolation: isolated (any Actor)? = #isolation,
  operation: () async throws -> R
) async rethrows -> R {
  try await SnapshotConfiguration.$current.withValue(
    SnapshotConfiguration(
      record: record ?? SnapshotConfiguration.current?.record ?? _record,
      diffTool: diffTool ?? SnapshotConfiguration.current?.diffTool ?? _diffTool
    )
  ) {
    try await operation()
  }
}

/// The configuration for a snapshot test.
public struct SnapshotConfiguration: Sendable {
  @_spi(Internals)
  @TaskLocal public static var current: Self?

  /// The diff tool use to print helpful test failure messages.
  ///
  /// See ``DiffTool-swift.struct`` for more information.
  public var diffTool: DiffTool?

  /// The recording strategy to use while running snapshot tests.
  ///
  /// See ``Record-swift.struct`` for more information.
  public var record: Record?

  public init(
    record: Record?,
    diffTool: DiffTool?
  ) {
    self.diffTool = diffTool
    self.record = record
  }

  /// The record mode of the snapshot test.
  ///
  /// There are 4 primary strategies for recording: ``Record-swift.struct/all``,
  /// ``Record-swift.struct/missing``, ``Record-swift.struct/never`` and
  /// ``Record-swift.struct/failed``
  public struct Record: Equatable, Sendable {
    private let storage: Storage

    public init?(rawValue: String) {
      switch rawValue {
      case "all":
        self.storage = .all
      case "failed":
        self.storage = .failed
      case "missing":
        self.storage = .missing
      case "never":
        self.storage = .never
      default:
        return nil
      }
    }

    /// Records all snapshots to disk, no matter what.
    public static let all = Self(storage: .all)

    /// Records snapshots for assertions that fail. This can be useful for tests that use precision
    /// thresholds so that passing tests do not re-record snapshots that are subtly different but
    /// still within the threshold.
    public static let failed = Self(storage: .failed)

    /// Records only the snapshots that are missing from disk.
    public static let missing = Self(storage: .missing)

    /// Does not record any snapshots. If a snapshot is missing a test failure will be raised. This
    /// option is appropriate when running tests on CI so that re-tries of tests do not
    /// surprisingly pass after snapshots are unexpectedly generated.
    public static let never = Self(storage: .never)

    private init(storage: Storage) {
      self.storage = storage
    }

    private enum Storage: Equatable, Sendable {
      case all
      case failed
      case missing
      case never
    }
  }

  /// Describes the diff command used to diff two files on disk.
  ///
  /// This type can be created with a closure that takes two arguments: the first argument is
  /// is a file path to the currently recorded snapshot on disk, and the second argument is the
  /// file path to a _failed_ snapshot that was recorded to a temporary location on disk. You can
  /// use these two file paths to construct a command that can be used to compare the two files.
  ///
  /// For example, to use ImageMagick's `compare` tool and pipe the result into Preview.app, you
  /// could create the following `DiffTool`:
  ///
  /// ```swift
  /// extension SnapshotConfiguration.DiffTool {
  ///   static let compare = Self {
  ///     "compare \"\($0)\" \"\($1)\" png: | open -f -a Preview.app"
  ///   }
  /// }
  /// ```
  ///
  /// `DiffTool` also comes with two values: ``DiffTool-swift.struct/ksdiff`` for printing a
  /// command for opening [Kaleidoscope](https://kaleidoscope.app), and
  /// ``DiffTool-swift.struct/default`` for simply printing the two URLs to the test failure
  /// message.
  public struct DiffTool: Sendable, ExpressibleByStringLiteral {
    var tool: @Sendable (_ currentFilePath: String, _ failedFilePath: String) -> String

    public init(
      _ tool: @escaping @Sendable (_ currentFilePath: String, _ failedFilePath: String) -> String
    ) {
      self.tool = tool
    }

    public init(stringLiteral value: StringLiteralType) {
      self.tool = { "\(value) \($0) \($1)" }
    }

    /// The [Kaleidoscope](http://kaleidoscope.app) diff tool.
    public static let ksdiff = Self {
      "ksdiff \"\($0)\" \"\($1)\""
    }

    /// The default diff tool.
    public static let `default` = Self {
      """
      @−
      "file://\($0)"
      @+
      "file://\($1)"

      To configure output for a custom diff tool, use 'withSnapshotConfiguration'. For example:

          withSnapshotConfiguration(diffTool: .ksdiff) {
            // ...
          }
      """
    }
    public func callAsFunction(currentFilePath: String, failedFilePath: String) -> String {
      self.tool(currentFilePath, failedFilePath)
    }
  }
}

@_spi(Internals)
public var _diffTool: SnapshotConfiguration.DiffTool {
  get {
    __diffTool.withLock { $0 }
  }
  set {
    __diffTool.withLock { $0 = newValue }
  }
}

private let __diffTool = Mutex<SnapshotConfiguration.DiffTool>(.default)

@_spi(Internals)
public var _record: SnapshotConfiguration.Record {
  get {
    __record.withLock { $0 }
  }
  set {
    __record.withLock { $0 = newValue }
  }
}

private let __record = Mutex<SnapshotConfiguration.Record>(
  {
    if let value = ProcessInfo.processInfo.environment["SNAPSHOT_TESTING_RECORD"],
      let record = SnapshotConfiguration.Record(rawValue: value)
    {
      return record
    }
    return .missing
  }()
)
