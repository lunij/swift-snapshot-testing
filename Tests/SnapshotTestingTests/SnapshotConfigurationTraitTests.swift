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

/// Verifies that snapshot configuration traits compose: siblings combine, the innermost value wins,
/// and a value left unspecified is inherited from the enclosing scope.
@Suite(.snapshotRecord(.failed), .snapshotDiffTool(.ksdiff))
struct SnapshotConfigurationTraitTests {
  @Test
  func `sibling traits on a suite combine`() {
    let configuration = resolvedConfiguration()
    #expect(configuration.diffTool == "ksdiff \"old.png\" \"new.png\"")
    #expect(configuration.record == .failed)
  }

  @Test(.snapshotDiffTool("ksdiff"))
  func `test trait overrides the diff tool and inherits the record mode`() {
    let configuration = resolvedConfiguration()
    #expect(configuration.diffTool == "ksdiff old.png new.png")
    #expect(configuration.record == .failed)
  }

  @Suite(.snapshotDiffTool("ksdiff"))
  struct OverrideDiffTool {
    @Test(.snapshotDiffTool("difftool"))
    func `innermost diff tool wins`() {
      let configuration = resolvedConfiguration()
      #expect(configuration.diffTool == "difftool old.png new.png")
      #expect(configuration.record == .failed)
    }

    @Suite(.snapshotRecord(.all))
    struct OverrideRecord {
      @Test
      func `record mode overrides while the diff tool is inherited`() {
        let configuration = resolvedConfiguration()
        #expect(configuration.diffTool == "ksdiff old.png new.png")
        #expect(configuration.record == .all)
      }

      @Suite(.snapshotRecord(.failed), .snapshotDiffTool("diff"))
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

  @Suite(.snapshotDiffTool("reversed"), .snapshotRecord(.never))
  struct ReversedSiblingOrder {
    @Test
    func `sibling order does not change the resolved configuration`() {
      let configuration = resolvedConfiguration()
      #expect(configuration.diffTool == "reversed old.png new.png")
      #expect(configuration.record == .never)
    }
  }

  @Suite(.snapshotRecord(.all))
  struct SiblingTraitsSplitAcrossScopes {
    @Test(.snapshotDiffTool("split"))
    func `a suite trait and a test trait combine`() {
      let configuration = resolvedConfiguration()
      #expect(configuration.diffTool == "split old.png new.png")
      #expect(configuration.record == .all)
    }
  }
}
