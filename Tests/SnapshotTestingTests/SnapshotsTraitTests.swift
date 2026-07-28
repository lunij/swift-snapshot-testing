import SnapshotTesting
@_spi(Internals) import Snapshotting
import Testing

/// The diff tool command that the enclosing trait hierarchy resolved to.
private func resolvedDiffTool() -> String? {
  SnapshotConfiguration.current?.diffTool?(
    currentFilePath: "old.png",
    failedFilePath: "new.png"
  )
}

/// The record mode that the enclosing trait hierarchy resolved to.
private func resolvedRecord() -> SnapshotConfiguration.Record? {
  SnapshotConfiguration.current?.record
}

/// Verifies that nested `.snapshots` traits compose: the innermost value wins, and a value left
/// unspecified is inherited from the enclosing scope.
@Suite(.snapshots(record: .failed, diffTool: .ksdiff))
struct SnapshotsTraitTests {
  @Test(.snapshots(diffTool: "ksdiff"))
  func testDiffTool() {
    #expect(resolvedDiffTool() == "ksdiff old.png new.png")
  }

  @Suite(.snapshots(diffTool: "ksdiff"))
  struct OverrideDiffTool {
    @Test(.snapshots(diffTool: "difftool"))
    func testDiffToolOverride() {
      #expect(resolvedDiffTool() == "difftool old.png new.png")
    }

    @Suite(.snapshots(record: .all))
    struct OverrideRecord {
      @Test
      func config() {
        #expect(resolvedDiffTool() == "ksdiff old.png new.png")
        #expect(resolvedRecord() == .all)
      }

      @Suite(.snapshots(record: .failed, diffTool: "diff"))
      struct OverrideDiffToolAndRecord {
        @Test
        func config() {
          #expect(resolvedDiffTool() == "diff old.png new.png")
          #expect(resolvedRecord() == .failed)
        }
      }
    }
  }
}
