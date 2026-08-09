import Synchronization
import Testing

/// The snapshot names one test has claimed.
///
/// Every snapshot claims the file it resolved to, and one taken without a name additionally claims
/// the stem it is numbered off — the number *is* how often that stem has been claimed, which is what
/// makes `.1`, `.2`, … count up in the order a test takes them.
///
/// A register belongs to a single test, so what one test claims is invisible to every other. Tests
/// run in parallel, and a lock they shared would be a lock every snapshot in the run queued behind.
/// The process-wide lock below is taken only to look a register up, never across rendering,
/// comparison or file I/O, and the per-test lock is held for a single dictionary update.
///
/// Registers are kept for the lifetime of the process. There is no end-of-test hook to drop one from
/// without a trait, and hanging their lifetime off an opt-in trait is what this replaces. The cost is
/// one entry per test that snapshots, plus one per name it claims.
final class Register: Sendable {
  /// Every register created so far, keyed by the test that owns it.
  ///
  /// `Test.Case` publishes no identity, so a test is the finest grain available. That is one register
  /// per test case for every test but a parameterized one, whose cases share both a test and,
  /// therefore, a register. Sharing costs them nothing, because ``SnapshotLocation`` folds the
  /// argument a snapshot was taken under into its name, so the keys the runs claim differ anyway. The
  /// `nil` key holds the register for snapshots taken outside a test.
  private static let registers = Mutex<[Test.ID?: Register]>([:])

  /// How often each key has been claimed.
  private let claims = Mutex<[String: Int]>([:])

  /// The register of the test that is running.
  static var current: Register {
    registers.withLock { registers in
      let id = Test.current?.id
      if let register = registers[id] { return register }
      let register = Register()
      registers[id] = register
      return register
    }
  }

  /// Claims `key`, reporting how many times this test has claimed it, this claim included.
  ///
  /// - Parameter key: What has to be unique within a test — a resolved reference file, or the stem an
  ///   unnamed snapshot is numbered off.
  /// - Returns: `1` the first time, counting up from there.
  func claim(_ key: String) -> Int {
    claims.withLock { claims in
      let count = claims[key, default: 0] + 1
      claims[key] = count
      return count
    }
  }
}
