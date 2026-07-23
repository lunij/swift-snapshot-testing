import XCTest

@testable import SnapshotTesting

@MainActor
class WaitTests: BaseTestCase {
  func testWait() async {
    var value = "Hello"
    Task { @MainActor in
      try? await Task.sleep(for: .seconds(1))
      value = "Goodbye"
    }

    let strategy = Snapshotting.lines.pullback { (_: Void) in
      value
    }

    await assertSnapshot(of: (), as: .wait(for: 1.5, on: strategy))
  }
}
