import Foundation

/// Customizes snapshotting for the duration of an operation.
///
/// Use this operation to customize how snapshots are recorded, and how failures are reported, for a
/// scoped region of code. The configuration is stored in a task local, so it applies to every
/// snapshot taken within `operation`, including nested ones.
///
/// - Parameters:
///   - record: The record mode to use while taking snapshots.
///   - diffTool: The diff tool to use while taking snapshots.
///   - operation: The operation to perform.
public func withSnapshotConfiguration<R>(
  record: SnapshotConfiguration.Record? = nil,
  diffTool: SnapshotConfiguration.DiffTool? = nil,
  operation: () throws -> R
) rethrows -> R {
  try SnapshotConfiguration.$current.withValue(
    SnapshotConfiguration(
      record: record ?? SnapshotConfiguration.current.record,
      diffTool: diffTool ?? SnapshotConfiguration.current.diffTool
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
      record: record ?? SnapshotConfiguration.current.record,
      diffTool: diffTool ?? SnapshotConfiguration.current.diffTool
    )
  ) {
    try await operation()
  }
}

/// The configuration for snapshotting, when to record a snapshot and what diff tool to use for snapshot comparison.
public struct SnapshotConfiguration: Sendable {
  @_spi(Internals)
  @TaskLocal public static var current = SnapshotConfiguration(
    record: processRecord,
    diffTool: .default
  )

  /// The diff tool use to print helpful failure messages.
  ///
  /// See ``DiffTool-swift.struct`` for more information.
  public var diffTool: DiffTool

  /// The recording strategy to use while taking snapshots.
  ///
  /// See ``Record-swift.struct`` for more information.
  public var record: Record

  public init(
    record: Record,
    diffTool: DiffTool
  ) {
    self.diffTool = diffTool
    self.record = record
  }

  /// The record mode to snapshot with.
  ///
  /// There are 4 primary strategies for recording: ``Record-swift.struct/all``,
  /// ``Record-swift.struct/missing``, ``Record-swift.struct/never`` and
  /// ``Record-swift.struct/failed``
  ///
  /// The default for a whole process can be set with the `SNAPSHOTTING_RECORD` environment
  /// variable, whose value is one of `all`, `failed`, `missing` or `never`. An unrecognized value
  /// is ignored, leaving the default of ``Record-swift.struct/missing``.
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

    /// Records snapshots for comparisons that fail. This is useful with precision thresholds, so
    /// that successful comparisons do not re-record snapshots that are subtly different but still
    /// within the threshold.
    public static let failed = Self(storage: .failed)

    /// Records only the snapshots that are missing from disk.
    public static let missing = Self(storage: .missing)

    /// Does not record any snapshots. If a snapshot is missing, a failure is reported. This option
    /// is appropriate on CI, so that a re-run does not surprisingly succeed after snapshots were
    /// unexpectedly generated.
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
  /// ``DiffTool-swift.struct/default`` for simply printing the two URLs to the failure message.
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

/// The record mode for the whole process, read from the `SNAPSHOTTING_RECORD` environment variable.
///
/// This seeds ``SnapshotConfiguration/current``, so it applies wherever neither an explicit argument
/// nor an enclosing ``withSnapshotConfiguration(record:diffTool:operation:)`` scope names a mode.
private let processRecord: SnapshotConfiguration.Record = {
  if let value = ProcessInfo.processInfo.environment["SNAPSHOTTING_RECORD"],
    let record = SnapshotConfiguration.Record(rawValue: value)
  {
    return record
  }
  return .failed
}()
