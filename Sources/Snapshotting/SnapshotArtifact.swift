import Foundation

/// A named blob produced while snapshotting, worth handing back to whoever ran the comparison.
///
/// Typically the snapshot that was just recorded, or a rendering of how it differs from its
/// reference. Artifacts are returned rather than reported anywhere, so what surfaces them — a test
/// harness, a log, a build report — is the caller's choice.
public struct SnapshotArtifact: Sendable, Equatable {
  /// A file name for the blob, including its extension.
  public let name: String

  /// The blob itself.
  public let data: Data

  public init(name: String, data: Data) {
    self.name = name
    self.data = data
  }
}
