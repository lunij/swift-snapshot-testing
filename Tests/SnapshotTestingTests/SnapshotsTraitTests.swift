import SnapshotTesting
@_spi(Internals) import Snapshotting
import Testing

/// The configuration that the enclosing trait hierarchy resolved to.
///
/// The diff tool is rendered against placeholder paths so that a test can compare it as a string.
private func resolvedConfiguration() -> (diffTool: String?, record: SnapshotConfiguration.Record?) {
  let configuration = SnapshotConfiguration.current
  return (
    configuration?.diffTool?(currentFilePath: "old.png", failedFilePath: "new.png"),
    configuration?.record
  )
}

/// Verifies that nested `.snapshots` traits compose: the innermost value wins, and a value left
/// unspecified is inherited from the enclosing scope.
@Suite(.snapshots(record: .failed, diffTool: .ksdiff))
struct SnapshotsTraitTests {
  @Test
  func `suite trait applies to its tests`() {
    let configuration = resolvedConfiguration()
    #expect(configuration.diffTool == "ksdiff \"old.png\" \"new.png\"")
    #expect(configuration.record == .failed)
  }

  @Test(.snapshots(diffTool: "ksdiff"))
  func `test trait overrides the diff tool and inherits the record mode`() {
    let configuration = resolvedConfiguration()
    #expect(configuration.diffTool == "ksdiff old.png new.png")
    #expect(configuration.record == .failed)
  }

  @Suite(.snapshots(diffTool: "ksdiff"))
  struct OverrideDiffTool {
    @Test(.snapshots(diffTool: "difftool"))
    func `innermost diff tool wins`() {
      let configuration = resolvedConfiguration()
      #expect(configuration.diffTool == "difftool old.png new.png")
      #expect(configuration.record == .failed)
    }

    @Suite(.snapshots(record: .all))
    struct OverrideRecord {
      @Test
      func `record mode overrides while the diff tool is inherited`() {
        let configuration = resolvedConfiguration()
        #expect(configuration.diffTool == "ksdiff old.png new.png")
        #expect(configuration.record == .all)
      }

      @Suite(.snapshots(record: .failed, diffTool: "diff"))
      struct OverrideDiffToolAndRecord {
        @Test
        func `both values override together`() {
          let configuration = resolvedConfiguration()
          #expect(configuration.diffTool == "diff old.png new.png")
          #expect(configuration.record == .failed)
        }
      }
    }
  }
}
