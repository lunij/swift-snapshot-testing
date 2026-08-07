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
package struct ProcessRecord: Sendable {
  /// The mode in effect when nothing else names one.
  package let record: SnapshotConfiguration.Record

  /// The value of `SNAPSHOT_RECORD` when it named a mode that does not exist.
  ///
  /// Kept rather than discarded so that a caller can report the misconfiguration. Silently falling
  /// back is the same trap as a variable that never arrived: someone who typed `nver` believes they
  /// asked for `never` and gets a run that writes.
  package let unrecognizedValue: String?

  /// The misconfiguration to report before taking any snapshot, or `nil` if there is none.
  package var warning: String? {
    unrecognizedValue.map {
      """
      'SNAPSHOT_RECORD' is set to '\($0)', which is not a record mode, so snapshots are being taken \
      with '\(record)'. Valid values are 'all', 'failed', 'missing' and 'never'.
      """
    }
  }

  /// How this process's environment resolved.
  package static let current = ProcessRecord(
    environment: ProcessInfo.processInfo.environment,
    isCI: .isCI
  )

  /// Resolves against an arbitrary environment, so that the precedence can be exercised without
  /// one. `isCI` is passed separately rather than read out of `environment` to keep the two signals
  /// independently controllable.
  package init(environment: [String: String], isCI: Bool) {
    let fallback: SnapshotConfiguration.Record = isCI ? .never : .failed
    guard let value = environment["SNAPSHOT_RECORD"] else {
      self.record = fallback
      self.unrecognizedValue = nil
      return
    }
    guard let record = SnapshotConfiguration.Record(rawValue: value) else {
      self.record = fallback
      self.unrecognizedValue = value
      return
    }
    self.record = record
    self.unrecognizedValue = nil
  }
}
