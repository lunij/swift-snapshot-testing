import Snapshotting
import Testing

@MainActor
struct WaitTests {
  @Test func wait() async {
    let start = ContinuousClock.now
    let strategy = SnapshotStrategy.lines.pullback { (_: Void) in
      start.duration(to: .now) >= .seconds(1.5) ? "Successfully waited" : "Failed to wait"
    }

    await expectSnapshot(of: (), as: .wait(for: 1.5, on: strategy))
  }
}
