import Foundation

extension Bool {
  /// Whether this process is running on a continuous integration server.
  ///
  /// Determined by the conventional `CI` environment variable, which is set to a non-empty value by
  /// every mainstream CI provider. Snapshotting reads it to pick the record mode a run falls back
  /// to: a reference recorded on CI is thrown away with the checkout, so recording there would turn
  /// a real mismatch into a green run.
  ///
  /// It is public because the same signal is worth having in a test suite, for a case that cannot
  /// pass on a runner:
  ///
  /// ```swift
  /// @Test(.disabled(if: .isCI))
  /// func rendersOnAGPU() async { … }
  /// ```
  ///
  /// `xcodebuild` does not pass the invoking shell's environment to the test process, so a job that
  /// drives it has to forward the variable as `TEST_RUNNER_CI`. An empty value counts as unset, so
  /// forwarding a variable that was never set locally does not make a local run look like CI.
  public static let isCI = isCI(in: ProcessInfo.processInfo.environment)

  /// Reads the signal out of an arbitrary environment, so that it can be exercised without one.
  static func isCI(in environment: [String: String]) -> Bool {
    !(environment["CI"] ?? "").isEmpty
  }
}
