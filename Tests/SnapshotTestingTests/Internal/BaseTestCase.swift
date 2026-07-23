import SnapshotTesting
import XCTest

@MainActor
class BaseTestCase: XCTestCase {
  override func invokeTest() {
    withSnapshotTesting(
      record: .failed,
      diffTool: .ksdiff
    ) {
      super.invokeTest()
    }
  }
}
