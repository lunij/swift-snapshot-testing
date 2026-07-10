#if compiler(>=6) && canImport(Testing)
  import Foundation
  import Testing
  import SnapshotTesting

  #if canImport(AppKit)
    import AppKit
  #endif

  #if canImport(UIKit)
    import UIKit
  #endif

  extension BaseSuite {
    @Suite(.serialized, .snapshots(record: .missing))
    struct SwiftTestingTests {
      // Verifies that a snapshot mismatch inside a Swift Testing test surfaces as a recorded
      // 'Issue' (and not a silently dropped 'XCTFail'). 'withKnownIssue' is the only way to
      // intercept that issue in-framework, so this is the one test that uses it.
      @Test func testSnapshot() {
        assertSnapshot(of: ["Hello", "World"], as: .dump, named: "snap")
        withKnownIssue {
          assertSnapshot(of: ["Goodbye", "World"], as: .dump, named: "snap")
        } matching: { issue in
          // The library's diff output prefixes context lines with U+2007 figure spaces, written
          // as explicit escapes here because they are indistinguishable from regular spaces.
          issue.description.contains(
            """
            @@ −1,4 +1,4 @@
            \u{2007}▿ 2 elements
            −  - "Hello"
            +  - "Goodbye"
            \u{2007}  - "World"
            """
          )
        }
      }

      #if canImport(UIKit)
        @Test func testUIImage() throws {
          let redPixel = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image {
            context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
          }
          let bluePixel = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image {
            context in
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
          }
          try verifyImageSnapshotting(reference: redPixel, mismatching: bluePixel)
        }
      #endif

      #if canImport(AppKit)
        @Test func testNSImage() throws {
          let redPixel = NSImage(size: NSSize(width: 1, height: 1), flipped: false) { rect in
            NSColor.red.setFill()
            rect.fill()
            return true
          }
          let bluePixel = NSImage(size: NSSize(width: 1, height: 1), flipped: false) { rect in
            NSColor.blue.setFill()
            rect.fill()
            return true
          }
          try verifyImageSnapshotting(reference: redPixel, mismatching: bluePixel)
        }
      #endif
    }
  }

  #if canImport(UIKit) || canImport(AppKit)
    #if canImport(UIKit)
      private typealias Image = UIImage
    #else
      private typealias Image = NSImage
    #endif

    /// Records `reference` into a temporary snapshot directory, then verifies that re-snapshotting
    /// it succeeds and that snapshotting `mismatching` fails with the expected message. Both images
    /// are rendered in-process, so the test does not depend on the machine's display scale.
    private func verifyImageSnapshotting(
      reference: Image,
      mismatching: Image,
      fileID: StaticString = #fileID,
      filePath: StaticString = #filePath,
      testName: String = #function,
      line: UInt = #line,
      column: UInt = #column
    ) throws {
      let snapshotDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent("SwiftTestingTests-\(UUID().uuidString)", isDirectory: true)
      defer { try? FileManager.default.removeItem(at: snapshotDirectory) }

      func verify(_ image: Image) -> String? {
        verifySnapshot(
          of: image,
          as: .image,
          named: "pixel",
          record: .missing,
          snapshotDirectory: snapshotDirectory.path,
          fileID: fileID,
          file: filePath,
          testName: testName,
          line: line,
          column: column
        )
      }

      let recordMessage = try #require(verify(reference))
      #expect(recordMessage.hasPrefix("No reference was found on disk. Automatically recorded snapshot"))
      #expect(verify(reference) == nil)

      let mismatchMessage = try #require(verify(mismatching))
      #expect(mismatchMessage.split(whereSeparator: \.isNewline).first == "[pixel] Image does not match reference.")
    }
  #endif
#endif
