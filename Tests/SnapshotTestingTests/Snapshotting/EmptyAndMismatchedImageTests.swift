#if os(iOS) || os(macOS) || os(tvOS)
import Foundation
import XCTest

@testable import SnapshotTesting

final class EmptyAndMismatchedImageTests: BaseTestCase {
  func testSnapshotWithZeroHeight_whenNoReferenceImage() async {
    let size = CGSize(width: 350, height: 0)
    let view = XView(frame: .init(origin: .zero, size: size))
    let message = await verifySnapshot(of: view, as: .image)
    XCTAssertEqual(message, "Snapshot test failed: Snapshot is empty")
  }

  func testSnapshotWithZeroWidth_whenNoReferenceImage() async {
    let size = CGSize(width: 0, height: 350)
    let view = XView(frame: .init(origin: .zero, size: size))
    let message = await verifySnapshot(of: view, as: .image)
    XCTAssertEqual(message, "Snapshot test failed: Snapshot is empty")
  }

  func testSnapshotWithZeroSize_whenNoReferenceImage() async {
    let view = XView(frame: .zero)
    let message = await verifySnapshot(of: view, as: .image)
    XCTAssertEqual(message, "Snapshot test failed: Snapshot is empty")
  }

  func testSnapshotWithZeroSize_whenReferenceImageExists() async {
    let view = XView(frame: .zero)
    let message = await verifySnapshot(of: view, as: .image)
    XCTAssertEqual(message, "Snapshot test failed: Snapshot is empty")
  }

  func testSnapshotWithUnequalSize() async {
    let size = CGSize(width: 100, height: 100)
    let view = XView(frame: .init(origin: .zero, size: size))
    var message = await verifySnapshot(of: view, as: .image, named: platform)
    XCTAssertNil(message)
    let newSize = CGSize(width: 123, height: 123)
    view.frame = .init(origin: .zero, size: newSize)
    message = await verifySnapshot(of: view, as: .image, named: platform, record: .never)
    let firstLine = message?.split(whereSeparator: \.isNewline).first
    #if os(macOS)
    XCTAssertEqual(firstLine, "[macos] Image size 123×123 does not match reference size 100×100.")
    #else
    XCTAssertEqual(firstLine, "[\(platform)] Image size 246×246 does not match reference size 200×200.")
    #endif
  }
}
#endif
