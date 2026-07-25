import Testing

@testable import SnapshotTesting

@MainActor
@Suite(.snapshots(record: .failed, diffTool: .ksdiff))
struct WaitTests {
  @Test func wait() async {
    var value = "Failed to wait"
    Task { @MainActor in
      try? await Task.sleep(for: .seconds(1))
      value = "Successfully waited"
    }

    let strategy = Snapshotting.lines.pullback { (_: Void) in
      value
    }

    await assertSnapshot(of: (), as: .wait(for: 1.5, on: strategy))
  }
}
