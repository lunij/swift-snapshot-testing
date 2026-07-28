import Foundation

/// A failure produced by a ``SnapshotComparator`` when two snapshot values do not match.
public struct SnapshotFailure: Sendable {
  /// A short, single-sentence description of what specifically failed.
  ///
  /// This becomes the first line of the failure message, which is the only line visible in Xcode's
  /// issue navigator and inline failure banner. It should state the concrete reason
  /// (e.g. a size mismatch or precision shortfall), not a generic "snapshot failed".
  public let reason: String

  /// Optional multi-line detail describing the failure, such as a text diff or a precision
  /// breakdown. Rendered below the reason in the failure message.
  public let detail: String?

  /// Artifacts describing the failure.
  public let artifacts: [Artifact]

  public init(reason: String, detail: String? = nil, artifacts: [Artifact] = []) {
    self.reason = reason
    self.detail = detail
    self.artifacts = artifacts
  }

  public struct Artifact: Sendable {
    public let name: String
    public let data: Data

    public init(name: String, data: Data) {
      self.name = name
      self.data = data
    }
  }
}
