import Testing

@testable import SnapshotTesting

@MainActor
@Suite(.snapshots(record: .failed, diffTool: .ksdiff))
struct WaitTests {
  @Test func wait() async {
    let start = ContinuousClock.now
    let strategy = Snapshotting.lines.pullback { (_: Void) in
      start.duration(to: .now) >= .seconds(1.5) ? "Successfully waited" : "Failed to wait"
    }
    await assertSnapshot(of: (), as: .wait(for: 1.5, on: strategy))
  }
}
