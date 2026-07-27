#if os(iOS) || os(macOS) || os(tvOS)
import Foundation
import Testing
@testable import SnapshotTesting
@testable import Snapshotting

#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

@MainActor
@Suite(.snapshots(record: .failed, diffTool: .ksdiff))
struct ImagePrecisionTests {
  @Test func `precision snapshot`() async {
    let view = XView(frame: .init(x: 0, y: 0, width: 100, height: 100))  // 10000 pixels
    view.backgroundColor = .blue
    await assertSnapshot(of: view, as: .image(precision: 1, perceptualPrecision: 1), named: "\(platform)-original")

    let subview = XView(frame: .init(x: 0, y: 0, width: 10, height: 10))  // 100 pixels
    subview.backgroundColor = .red
    view.addSubview(subview)
    await assertSnapshot(of: view, as: .image(precision: 1, perceptualPrecision: 1), named: "\(platform)-modified")

    var message = await verifySnapshot(of: view, as: .image(precision: 0.999, perceptualPrecision: 1), named: "\(platform)-original", record: .never)
    let firstLine = message?.split(whereSeparator: \.isNewline).first
    #expect(firstLine == "[\(platform)-original] Image does not match reference (pixel precision 0.995 is less than required 0.999).")

    // 10000-100=9900 => 99% precision
    message = await verifySnapshot(of: view, as: .image(precision: 0.99, perceptualPrecision: 1), named: "\(platform)-original", record: .never)
    #expect(message == nil)
  }

  @Test func `perceptual precision snapshot`() async {
    let view = XView(frame: .init(x: 0, y: 0, width: 100, height: 100))
    view.backgroundColor = .black
    await assertSnapshot(of: view, as: .image(precision: 1, perceptualPrecision: 1), named: platform + "-original")

    view.backgroundColor = .init(white: 0.0019, alpha: 1)
    await assertSnapshot(of: view, as: .image(precision: 1, perceptualPrecision: 1), named: platform + "-modified")

    await assertSnapshot(of: view, as: .image(precision: 1, perceptualPrecision: 0.98), named: platform + "-original", record: .never)
  }
}

extension XImage {
  convenience init?(contentsOf url: URL) {
    #if os(iOS) || os(tvOS)
    self.init(contentsOfFile: url.path)
    #elseif os(macOS)
    self.init(byReferencing: url)
    #endif
  }
}

#if os(macOS)
extension XView {
  var backgroundColor: NSColor? {
    get {
      guard let cgColor = layer?.backgroundColor else { return nil }
      return NSColor(cgColor: cgColor)
    }
    set {
      wantsLayer = true
      layer?.backgroundColor = newValue?.cgColor
    }
  }
}
#endif
#endif
