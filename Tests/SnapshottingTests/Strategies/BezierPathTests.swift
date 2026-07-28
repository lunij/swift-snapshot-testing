#if os(iOS) || os(macOS) || os(tvOS)
import Snapshotting
import Testing

#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

struct BezierPathTests {
  @Test func `CGPath snapshot`() async {
    let path = CGPath.heart
    await expectSnapshot(of: path, as: .image, named: platform)
    await expectSnapshot(of: path, as: .elementsDescription, named: platform)
  }

  #if os(macOS)
  @Test func `NSBezierPath snapshot`() async {
    let path = NSBezierPath.heart
    await expectSnapshot(of: path, as: .image, named: platform)
    await expectSnapshot(of: path, as: .elementsDescription, named: platform)
  }
  #endif

  #if os(iOS) || os(tvOS)
  @Test func `UIBezierPath snapshot`() async {
    let path = UIBezierPath.heart
    await expectSnapshot(of: path, as: .image, named: platform)
    await expectSnapshot(of: path, as: .elementsDescription, named: platform)
  }
  #endif
}
#endif
