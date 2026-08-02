import Foundation
import SnapshotTesting
import Testing

// Covers the two plural 'assertSnapshots' overloads, which are wrapper API with no engine
// equivalent. The array overload is also the only remaining exercise of the per-test counter that
// names unnamed snapshots '.1', '.2', … in the order they are taken.
//
// The subject is a value rather than a view: what these overloads do with a strategy is the same
// whatever the strategy renders, and a value keeps the suite on every platform the package builds
// for, with references small enough to read in a diff.
@Suite(.snapshotRecord(.failed), .snapshotDiffTool(.ksdiff))
struct AssertSnapshotsTests {
  @Test func `multiple snapshots`() async {
    struct User: Encodable { let id: Int, name: String, bio: String }
    let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")

    let compact = JSONEncoder()
    compact.outputFormatting = .sortedKeys

    await assertSnapshots(of: user, as: ["pretty": .json, "compact": .json(compact)])
    await assertSnapshots(of: user, as: [.json, .plist])
  }
}
