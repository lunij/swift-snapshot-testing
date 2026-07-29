import Foundation

/// A failure produced by a ``SnapshotComparator`` when two snapshot values do not match.
public struct SnapshotFailure: Sendable, Equatable {
  /// A short, single-sentence description of what specifically failed.
  ///
  /// This becomes the first line of the rendered failure message, and hosts that surface only one
  /// line of a failure show that one. It should state the concrete reason (e.g. a size mismatch or
  /// precision shortfall), not a generic "snapshot failed".
  public let reason: String

  /// Optional multi-line detail describing the failure, such as a text diff or a precision
  /// breakdown. Rendered below the reason in the failure message.
  public let detail: String?

  /// Artifacts describing the failure.
  public let artifacts: [SnapshotArtifact]

  public init(reason: String, detail: String? = nil, artifacts: [SnapshotArtifact] = []) {
    self.reason = reason
    self.detail = detail
    self.artifacts = artifacts
  }
}
