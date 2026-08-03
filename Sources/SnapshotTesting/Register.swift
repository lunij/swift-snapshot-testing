import Foundation
import Synchronization

/// The reference files the snapshots of one test have resolved to.
///
/// Two snapshots that resolve to the same name may share a reference as long as neither records to
/// it: both then read the same file and report honestly, which is what lets a test read one
/// reference twice over. It is *recording* that makes a repeat meaningless — the second snapshot
/// would be compared against whatever the first one wrote, and then overwrite it. The register is
/// what lets that be reported instead of happening.
///
/// A suffix does not make a repeat legitimate. It is one more component of a name, so two snapshots
/// given the same suffix collide exactly as two given none do.
final class Register: Sendable {
  @TaskLocal static var current = Register()

  /// The files claimed so far, each with whether the snapshot that claimed it records there.
  private let claims = Mutex<[URL: Bool]>([:])

  init() {}

  /// Claims `url` for the current test, reporting whether this snapshot has to be told apart from an
  /// earlier one.
  ///
  /// - Parameters:
  ///   - url: The reference this snapshot resolved to.
  ///   - willRecord: Whether this snapshot records to `url`.
  /// - Returns: `true` when an earlier snapshot claimed `url` and either of the two records there.
  ///   A refused snapshot is not taken, so the claim it would have made is not registered.
  func claim(_ url: URL, recording willRecord: Bool) -> Bool {
    claims.withLock { claims in
      guard let hasRecorded = claims[url] else {
        claims[url] = willRecord
        return false
      }
      return hasRecorded || willRecord
    }
  }
}
