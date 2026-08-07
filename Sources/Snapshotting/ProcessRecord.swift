import Foundation

/// The record mode a whole process falls back to.
///
/// This seeds ``SnapshotConfiguration/current``, so it applies wherever neither an explicit argument
/// nor an enclosing ``withSnapshotConfiguration(record:diffTool:operation:)`` scope names a mode.
///
/// Two things decide it. `SNAPSHOT_RECORD` names a mode outright and always wins, which is what a
/// deliberate re-recording run sets. Without it, the mode depends on where the run is: ``Bool/isCI``
/// picks ``SnapshotConfiguration/Record-swift.struct/never``, because a reference recorded on a
/// runner is discarded with the checkout and would turn a real mismatch into a green run, and
/// anywhere else picks ``SnapshotConfiguration/Record-swift.struct/failed``, so that an intended
/// change lands as a diff of the reference file in one run rather than two.
@_spi(Internals)
public struct ProcessRecord: Sendable {
  /// The mode in effect when nothing else names one.
  public let record: SnapshotConfiguration.Record

  /// How this process's environment resolved.
  public static let current = ProcessRecord(
    environment: ProcessInfo.processInfo.environment,
    isCI: .isCI
  )

  /// Resolves against an arbitrary environment, so that the precedence can be exercised without
  /// one. `isCI` is passed separately rather than read out of `environment` to keep the two signals
  /// independently controllable.
  @_spi(Internals)
  public init(environment: [String: String], isCI: Bool) {
    let fallback: SnapshotConfiguration.Record = isCI ? .never : .failed
    guard
      let value = environment["SNAPSHOT_RECORD"],
      let record = SnapshotConfiguration.Record(rawValue: value)
    else {
      self.record = fallback
      return
    }
    self.record = record
  }
}
