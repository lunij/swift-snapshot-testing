import InlineSnapshotTesting
import SnapshottingCustomDump
import Testing

@Suite(.snapshotRecord(.failed), .snapshotDiffTool(.ksdiff))
struct CustomDumpSnapshotTests {
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
