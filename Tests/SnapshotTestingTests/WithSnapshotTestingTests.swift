import Testing

@_spi(Internals) @testable import SnapshotTesting

struct WithSnapshotTestingTests {
  @Test func nesting() {
    withSnapshotTesting(record: .all) {
      #expect(
        SnapshotTestingConfiguration.current?
          .diffTool?(currentFilePath: "old.png", failedFilePath: "new.png") == """
            @−
            "file://old.png"
            @+
            "file://new.png"

            To configure output for a custom diff tool, use 'withSnapshotTesting'. For example:

                withSnapshotTesting(diffTool: .ksdiff) {
                  // ...
                }
            """
      )
      #expect(SnapshotTestingConfiguration.current?.record == .all)
      withSnapshotTesting(diffTool: "ksdiff") {
        let command = SnapshotTestingConfiguration.current?
          .diffTool?(currentFilePath: "old.png", failedFilePath: "new.png")
        #expect(command == "ksdiff old.png new.png")
        #expect(SnapshotTestingConfiguration.current?.record == .all)
      }
    }
  }
}
