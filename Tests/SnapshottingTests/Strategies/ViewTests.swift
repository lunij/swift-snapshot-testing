#if os(iOS) || os(macOS)
import Snapshotting
import Testing

#if os(iOS)
import UIKit
#else
import AppKit
#endif

@MainActor
struct ViewTests {
  #if os(macOS)
  @Test func `nsview`() async {
    let button = NSButton()
    button.bezelStyle = .rounded
    button.title = "Push Me"
    button.sizeToFit()
    await expectSnapshot(of: button, as: .image, named: "\(platform)\(osVersion.majorVersion)")
    await expectSnapshot(of: button, as: .recursiveDescription, named: "\(platform)\(osVersion.majorVersion)")
  }

  @Test func `nsview with layer`() async {
    let view = NSView()
    view.frame = CGRect(x: 0, y: 0, width: 10, height: 10)
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.green.cgColor
    view.layer?.cornerRadius = 5
    await expectSnapshot(of: view, as: .image, named: "\(platform)\(osVersion.majorVersion)")
    await expectSnapshot(of: view, as: .recursiveDescription, named: platform)
  }
  #endif

  #if os(iOS)
  @Test func `uiview`() async {
    let view = UIButton(type: .contactAdd)
    await expectSnapshot(of: view, as: .image)
    await expectSnapshot(of: view, as: .recursiveDescription)
  }
  #endif
}
#endif
