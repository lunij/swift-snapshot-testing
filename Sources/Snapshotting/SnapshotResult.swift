import Foundation

/// The outcome of comparing a value against a reference snapshot.
public struct SnapshotResult: Sendable {
  /// What happened when the value was compared against its reference.
  ///
  /// This is the primary output. ``failureMessage`` renders it into prose for callers that want to
  /// show it to a human, but anything deciding what to *do* about a comparison should switch over
  /// this instead of matching on strings.
  public enum Outcome: Sendable, Equatable {
    /// The value matched its reference.
    case matched

    /// The value did not match its reference.
    case mismatched(SnapshotFailure)

    /// Recording was on, so the reference was written without being compared.
    case recordModeOn

    /// No reference existed, so one was recorded.
    case referenceRecorded

    /// No reference existed and recording is disabled, so nothing was written.
    case referenceMissing

    /// A reference existed but could not be decoded. Carries the underlying reason.
    case referenceUnreadable(String)

    /// Snapshotting the value itself failed. Carries the underlying reason.
    case errored(String)
  }

  /// What happened when the value was compared against its reference.
  public let outcome: Outcome

  /// The reference the value was compared against.
  public let snapshotURL: URL

  /// Where a mismatching snapshot was written so that it can be diffed against the reference, or
  /// `nil` if there was nothing to write.
  public let artifactURL: URL?

  /// The description the comparison was given, used to disambiguate a failure message when a value
  /// is snapshot several times over.
  public let name: String?

  /// Whether a reference file was written to disk.
  ///
  /// This is not implied by ``outcome``: a mismatch under ``SnapshotConfiguration/Record/failed``
  /// both fails *and* re-records.
  public let recorded: Bool

  /// A command that opens the reference and the mismatching snapshot in the configured diff tool.
  ///
  /// Resolved when the comparison runs rather than when the message is rendered, because the diff
  /// tool comes from a task local that is no longer in scope by the time a caller reads this.
  public let diffCommand: String?

  /// Artifacts worth surfacing to whoever ran the comparison, such as the recorded snapshot or a
  /// rendering of the difference.
  ///
  /// These are returned rather than reported directly so that the comparison itself stays free of
  /// side effects. They are produced whether or not the value matched — recording a reference yields
  /// one even though nothing failed.
  public let artifacts: [SnapshotArtifact]

  public init(
    outcome: Outcome,
    snapshotURL: URL,
    artifactURL: URL? = nil,
    name: String? = nil,
    recorded: Bool = false,
    diffCommand: String? = nil,
    artifacts: [SnapshotArtifact] = []
  ) {
    self.outcome = outcome
    self.snapshotURL = snapshotURL
    self.artifactURL = artifactURL
    self.name = name
    self.recorded = recorded
    self.diffCommand = diffCommand
    self.artifacts = artifacts
  }

  /// The outcome rendered for a human, or `nil` if the value matched its reference.
  ///
  /// The first line is a self-contained summary of what went wrong. Hosts that surface only one
  /// line of a failure show that one, so everything below it is ordered by decreasing usefulness:
  /// failure detail, then file URLs and the diff tool command.
  public var failureMessage: String? {
    switch outcome {
    case .matched:
      return nil

    case .mismatched(let failure):
      var message = name.map { "[\($0)] \(failure.reason)" } ?? failure.reason

      if recorded {
        message += " A new snapshot was automatically recorded."
      }

      if let detail = failure.detail?.trimmingCharacters(in: .whitespacesAndNewlines),
        !detail.isEmpty
      {
        message += "\n\n\(detail)"
      }

      return """
        \(message)

        \(diffCommand ?? "")
        """

    case .recordModeOn:
      return """
        Record mode is on. Automatically recorded snapshot: …

        open "\(snapshotURL.absoluteString)"

        Turn record mode off and re-run to compare against the newly-recorded snapshot
        """

    case .referenceRecorded:
      return """
        No reference was found on disk. Automatically recorded snapshot: …

        open "\(snapshotURL.absoluteString)"

        Re-run to compare against the newly-recorded snapshot.
        """

    case .referenceMissing:
      return """
        No reference was found on disk. New snapshot was not recorded because recording is disabled
        """

    case .referenceUnreadable(let reason):
      return """
        Couldn't load reference snapshot: \(reason)

        The reference file may be corrupt. Delete it and re-run to record a new one:

        open "\(snapshotURL.absoluteString)"
        """

    case .errored(let reason):
      return "Snapshot failed: \(reason)"
    }
  }
}
