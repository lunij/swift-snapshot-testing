#if os(iOS) || os(macOS)
#if os(iOS)
import UIKit
#else
import AppKit
#endif

import XCTest

@testable import SnapshotTesting

final class ViewTests: BaseTestCase {
  #if os(macOS)
  func testNSView() async {
    let button = NSButton()
    button.bezelStyle = .rounded
    button.title = "Push Me"
    button.sizeToFit()
    await assertSnapshot(of: button, as: .image, named: "\(platform)\(osVersion.majorVersion)")
    await assertSnapshot(of: button, as: .recursiveDescription, named: "\(platform)\(osVersion.majorVersion)")
  }

  func testNSViewWithLayer() async {
    let view = NSView()
    view.frame = CGRect(x: 0, y: 0, width: 10, height: 10)
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.green.cgColor
    view.layer?.cornerRadius = 5
    await assertSnapshot(of: view, as: .image, named: "\(platform)\(osVersion.majorVersion)")
    await assertSnapshot(of: view, as: .recursiveDescription, named: platform)
  }
  #endif

  #if os(iOS)
  func testUIView() async {
    let view = UIButton(type: .contactAdd)
    await assertSnapshot(of: view, as: .image)
    await assertSnapshot(of: view, as: .recursiveDescription)
  }
  #endif
}
#endif
