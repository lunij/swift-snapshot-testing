#if os(iOS) || os(macOS) || os(tvOS)
import Snapshotting
import Testing

#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

@MainActor
struct ViewTests {
  #if os(macOS)
  @Test func `nsview`() async {
    let button = NSButton()
    button.bezelStyle = .rounded
    button.title = "Push Me"
    button.sizeToFit()
    await expectSnapshot(of: button, as: .image)
    await expectSnapshot(of: button, as: .recursiveDescription)
  }

  @Test func `nsview with layer`() async {
    let view = NSView()
    view.frame = CGRect(x: 0, y: 0, width: 10, height: 10)
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.green.cgColor
    view.layer?.cornerRadius = 5
    await expectSnapshot(of: view, as: .image)
    await expectSnapshot(of: view, as: .recursiveDescription)
  }
  #endif

  #if os(iOS) || os(tvOS)
  @Test func `uiview`() async {
    let button = UIButton(type: .system)
    button.setTitle("Push Me", for: .normal)
    button.sizeToFit()
    await expectSnapshot(of: button, as: .image)
    await expectSnapshot(of: button, as: .recursiveDescription)
  }

  @Test func `uiview with layer`() async {
    let view = UIView()
    view.frame = CGRect(x: 0, y: 0, width: 10, height: 10)
    view.layer.backgroundColor = UIColor.green.cgColor
    view.layer.cornerRadius = 5
    // The image has a reference per platform because the render scale differs — 20 × 20 pixels on a
    // phone against 10 × 10 on an Apple TV — while the description is in points, so it is shared.
    await expectSnapshot(of: view, as: .image)
    await expectSnapshot(of: view, as: .recursiveDescription)
  }
  #endif
}
#endif
