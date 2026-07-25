import XCTest

@testable import SnapshotTesting

final class CaseIterableTests: BaseTestCase {
  func testCaseIterable() async {
    enum Direction: String, CaseIterable {
      case up, down, left, right
      var rotatedLeft: Direction {
        switch self {
        case .up: return .left
        case .down: return .right
        case .left: return .down
        case .right: return .up
        }
      }
    }

    await assertSnapshot(
      of: { $0.rotatedLeft },
      as: Snapshotting<Direction, String>.func(into: .description)
    )
  }
}
