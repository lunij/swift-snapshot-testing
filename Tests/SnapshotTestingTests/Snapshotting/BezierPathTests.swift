#if os(iOS) || os(macOS) || os(tvOS)
import SnapshotTesting
import Testing

#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

@Suite(.snapshots(record: .failed, diffTool: .ksdiff))
struct BezierPathTests {
  @Test func `CGPath snapshot`() async {
    let path = CGPath.heart
    await assertSnapshot(of: path, as: .image, named: platform)
    await assertSnapshot(of: path, as: .elementsDescription, named: platform)
  }

  #if os(macOS)
  @Test func `NSBezierPath snapshot`() async {
    let path = NSBezierPath.heart
    await assertSnapshot(of: path, as: .image, named: platform)
    await assertSnapshot(of: path, as: .elementsDescription, named: platform)
  }
  #endif

  #if os(iOS) || os(tvOS)
  @Test func `UIBezierPath snapshot`() async {
    let path = UIBezierPath.heart
    await assertSnapshot(of: path, as: .image, named: platform)
    await assertSnapshot(of: path, as: .elementsDescription, named: platform)
  }
  #endif
}
#endif
