import Foundation

/// The outcome of comparing a value against a reference snapshot.
public struct SnapshotResult: Sendable {
  /// A message describing why the value did not match its reference, or `nil` if it matched.
  public let failure: String?

  /// Artifacts worth surfacing to whoever ran the comparison, such as the recorded snapshot or a
  /// rendering of the difference.
  ///
  /// These are returned rather than reported directly so that the comparison itself stays free of
  /// side effects.
  public let attachments: [SnapshotFailure.Artifact]

  public init(failure: String? = nil, attachments: [SnapshotFailure.Artifact] = []) {
    self.failure = failure
    self.attachments = attachments
  }
}
