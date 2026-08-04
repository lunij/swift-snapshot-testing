import InlineSnapshotTesting
import SnapshottingCustomDump
import Testing

@Suite(.snapshotRecord(.failed), .snapshotDiffTool(.ksdiff))
struct CustomDumpSnapshotTests {
  // A custom dump is one of several text renderings of the same value, so it names itself rather
  // than relying on the `txt` it shares with them.
  @Test func `the strategy identifies itself`() {
    #expect(SnapshotStrategy<Int, String>.customDump.identifier == "custom-dump")
  }

  @Test func basics() async {
    struct User { let id: Int, name: String, bio: String }
    let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")
    await assertInlineSnapshot(of: user, as: .customDump) {
      """
      CustomDumpSnapshotTests.User(
        id: 1,
        name: "Blobby",
        bio: "Blobbed around the world."
      )
      """
    }
  }
}
