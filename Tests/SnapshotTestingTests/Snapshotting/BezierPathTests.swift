import XCTest

@testable import SnapshotTesting

#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

final class BezierPathTests: BaseTestCase {
  #if os(iOS) || os(macOS) || os(tvOS)
  func testCGPath() async {
    let path = CGPath.heart
    await assertSnapshot(of: path, as: .image, named: platform)
    await assertSnapshot(of: path, as: .elementsDescription, named: platform)
  }
  #endif

  #if os(macOS)
  func testNSBezierPath() async {
    let path = NSBezierPath.heart
    await assertSnapshot(of: path, as: .image, named: platform)
    await assertSnapshot(of: path, as: .elementsDescription, named: platform)
  }
  #endif

  func testUIBezierPath() async {
    #if os(iOS) || os(tvOS)
    let path = UIBezierPath.heart

    let osName: String
    #if os(iOS)
    osName = "iOS"
    #elseif os(tvOS)
    osName = "tvOS"
    #endif

    if !CI {
      await assertSnapshot(of: path, as: .image, named: osName)
    }

    if #available(iOS 11.0, tvOS 11.0, *) {
      await assertSnapshot(of: path, as: .elementsDescription, named: osName)
    }
    #endif
  }
}
