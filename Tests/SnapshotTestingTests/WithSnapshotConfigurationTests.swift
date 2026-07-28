import Testing

@_spi(Internals) @testable import SnapshotTesting

struct WithSnapshotConfigurationTests {
  @Test func nesting() {
    withSnapshotConfiguration(record: .all) {
      #expect(
        SnapshotConfiguration.current?
          .diffTool?(currentFilePath: "old.png", failedFilePath: "new.png") == """
            @−
            "file://old.png"
            @+
            "file://new.png"

            To configure output for a custom diff tool, use 'withSnapshotConfiguration'. For example:

                withSnapshotConfiguration(diffTool: .ksdiff) {
                  // ...
                }
            """
      )
      #expect(SnapshotConfiguration.current?.record == .all)
      withSnapshotConfiguration(diffTool: "ksdiff") {
        let command = SnapshotConfiguration.current?
          .diffTool?(currentFilePath: "old.png", failedFilePath: "new.png")
        #expect(command == "ksdiff old.png new.png")
        #expect(SnapshotConfiguration.current?.record == .all)
      }
    }
  }
}
