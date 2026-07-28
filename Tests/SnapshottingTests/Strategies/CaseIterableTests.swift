import Snapshotting
import Testing

struct CaseIterableTests {
  @Test func `CaseIterable snapshot`() async {
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

    await expectSnapshot(
      of: { $0.rotatedLeft },
      as: SnapshotStrategy<Direction, String>.func(into: .description)
    )
  }
}
