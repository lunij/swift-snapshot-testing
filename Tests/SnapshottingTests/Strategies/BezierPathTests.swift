#if canImport(AppKit) || canImport(UIKit)
import Snapshotting
import Testing

#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

struct BezierPathTests {
  @Test func `cgPath`() async {
    let path = CGPath.fixture
    await expectSnapshot(of: path, as: .image)
    await expectSnapshot(of: path, as: .elementsDescription)
  }

  @Test func `bezier path`() async {
    #if canImport(AppKit)
    let path = NSBezierPath.fixture
    let name = "appkit"
    #elseif canImport(UIKit)
    let path = UIBezierPath.fixture
    let name = "uikit"
    #endif
    await expectSnapshot(of: path, as: .image, named: name)
    await expectSnapshot(of: path, as: .elementsDescription, named: name)
  }
}
#endif
