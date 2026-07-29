import Foundation
import SnapshotTesting
import Testing

#if canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

@Suite(.serialized, .snapshotRecord(.missing), .snapshotDiffTool(.ksdiff))
struct SwiftTestingTests {
  @Test func `reports on mismatch`() async {
    let issues = await captureIssues {
      await assertSnapshot(of: ["Hello", "World"], as: .dump, named: "snap")
      await assertSnapshot(of: ["Goodbye", "World"], as: .dump, named: "snap")
    }
    #expect(issues.count == 1)
    #expect(issues.first?.message.hasPrefix("[snap] Text does not match reference") == true)
    #expect(issues.first?.sourceLocation.fileID == #fileID)
  }

  #if canImport(UIKit)
  @Test func `snapshotting UIImage`() async throws {
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
    try await verifyImageSnapshotting(reference: redPixel, mismatching: bluePixel)
  }
  #endif

  #if canImport(AppKit)
  @Test func `snapshotting NSImage`() async throws {
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
    try await verifyImageSnapshotting(reference: redPixel, mismatching: bluePixel)
  }
  #endif

  #if canImport(AppKit) || canImport(UIKit)
  // A reference file that can't be decoded as an image must produce a test failure with a
  // readable message, not crash the test process.
  @Test func testCorruptImageReference() async throws {
    let snapshotDirectory = FileManager.default.temporaryDirectory
      .appending(path: "SwiftTestingTests-\(UUID().uuidString)", directoryHint: .isDirectory)
    defer { try? FileManager.default.removeItem(at: snapshotDirectory) }

    func verify() async -> String? {
      await verifySnapshot(
        of: redPixelImage(),
        as: .image,
        named: "pixel",
        record: .missing,
        snapshotDirectory: snapshotDirectory.path
      ).failureMessage
    }

    let recordMessage = try #require(await verify())
    #expect(recordMessage.hasPrefix("No reference was found on disk."))
    #expect(await verify() == nil)

    let referenceURL = try #require(
      try FileManager.default
        .contentsOfDirectory(at: snapshotDirectory, includingPropertiesForKeys: nil)
        .first { $0.pathExtension == "png" }
    )
    try Data("not a png".utf8).write(to: referenceURL)

    let failure = try #require(await verify())
    #expect(failure.hasPrefix("Couldn't load reference snapshot:"))
  }
  #endif
}

#if canImport(AppKit) || canImport(UIKit)
#if canImport(AppKit)
private typealias XImage = NSImage
#else
private typealias XImage = UIImage
#endif

private func redPixelImage() -> XImage {
  #if canImport(AppKit)
  return NSImage(size: NSSize(width: 1, height: 1), flipped: false) { rect in
    NSColor.red.setFill()
    rect.fill()
    return true
  }
  #else
  return UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { context in
    UIColor.red.setFill()
    context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
  }
  #endif
}

/// Records `reference` into a temporary snapshot directory, then verifies that re-snapshotting
/// it succeeds and that snapshotting `mismatching` fails with the expected message. Both images
/// are rendered in-process, so the test does not depend on the machine's display scale.
private func verifyImageSnapshotting(
  reference: XImage,
  mismatching: XImage,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  testName: String = #function,
  line: UInt = #line,
  column: UInt = #column
) async throws {
  let snapshotDirectory = FileManager.default.temporaryDirectory
    .appending(path: "SwiftTestingTests-\(UUID().uuidString)", directoryHint: .isDirectory)
  defer { try? FileManager.default.removeItem(at: snapshotDirectory) }

  func verify(_ image: XImage) async -> String? {
    await verifySnapshot(
      of: image,
      as: .image,
      named: "pixel",
      record: .missing,
      snapshotDirectory: snapshotDirectory.path,
      file: filePath,
      testName: testName
    ).failureMessage
  }

  let recordMessage = try #require(await verify(reference))
  #expect(recordMessage.hasPrefix("No reference was found on disk. Automatically recorded snapshot"))
  #expect(await verify(reference) == nil)

  let mismatchMessage = try #require(await verify(mismatching))
  #expect(mismatchMessage.split(whereSeparator: \.isNewline).first == "[pixel] Image does not match reference.")
}
#endif
