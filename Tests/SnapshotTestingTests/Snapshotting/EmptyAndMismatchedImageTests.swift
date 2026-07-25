#if os(iOS) || os(macOS) || os(tvOS)
import Foundation
import Testing
@testable import SnapshotTesting

@MainActor
@Suite(.snapshots(record: .failed, diffTool: .ksdiff))
struct EmptyAndMismatchedImageTests {
  @Test func `image with zero height`() async {
    let size = CGSize(width: 350, height: 0)
    let view = XView(frame: .init(origin: .zero, size: size))
    let message = await verifySnapshot(of: view, as: .image)
    #expect(message == "Snapshot test failed: Snapshot is empty")
  }

  @Test func `image with zero width`() async {
    let size = CGSize(width: 0, height: 350)
    let view = XView(frame: .init(origin: .zero, size: size))
    let message = await verifySnapshot(of: view, as: .image)
    #expect(message == "Snapshot test failed: Snapshot is empty")
  }

  @Test func `image with zero size`() async {
    let view = XView(frame: .zero)
    let message = await verifySnapshot(of: view, as: .image)
    #expect(message == "Snapshot test failed: Snapshot is empty")
  }

  @Test func `image with size mismatch`() async {
    let size = CGSize(width: 100, height: 100)
    let view = XView(frame: .init(origin: .zero, size: size))
    var message = await verifySnapshot(of: view, as: .image, named: platform)
    #expect(message == nil)
    let newSize = CGSize(width: 123, height: 123)
    view.frame = .init(origin: .zero, size: newSize)
    message = await verifySnapshot(of: view, as: .image, named: platform, record: .never)
    let firstLine = message?.split(whereSeparator: \.isNewline).first
    #if os(macOS)
    #expect(firstLine == "[macos] Image size 123×123 does not match reference size 100×100.")
    #else
    #expect(firstLine == "[\(platform)] Image size 246×246 does not match reference size 200×200.")
    #endif
  }
}
#endif
