#if canImport(SwiftUI)
import SwiftUI
import XCTest

@testable import SnapshotTesting

final class SwiftUIViewTests: BaseTestCase {
  struct SwiftUIView: View {
    var body: some View {
      ZStack {
        Color.green
        Color.yellow.padding()
        Color.red.frame(minWidth: 5, minHeight: 5).padding().padding()
      }
    }
  }

  #if os(macOS)
  func testSwiftUIView() async {
    let view = SwiftUIView()
    await assertSnapshot(of: view, as: .image(layout: .fixed(width: 100, height: 100)), named: "\(platform)\(osVersion.majorVersion)-fixed")
    await assertSnapshot(of: view, as: .image(layout: .sizeThatFits), named: "\(platform)\(osVersion.majorVersion)-size-that-fits")
  }
  #endif

  #if os(iOS)
  func testSwiftUIView() async {
    let view = SwiftUIView()
    await assertSnapshot(
      of: view,
      as: .image(layout: .fixed(width: 100, height: 100), traits: { $0.userInterfaceStyle = .light }),
      named: "\(platform)-fixed"
    )
    await assertSnapshot(of: view, as: .image(layout: .sizeThatFits, traits: { $0.userInterfaceStyle = .light }), named: "\(platform)-size-that-fits")
    await assertSnapshot(
      of: view,
      as: .image(layout: .device(config: .iPhoneSe), traits: { $0.userInterfaceStyle = .light }),
      named: "\(platform)-device"
    )
  }
  #endif

  #if os(tvOS)
  func testSwiftUIView() async {
    let view = SwiftUIView()
    await assertSnapshot(of: view, as: .image(layout: .fixed(width: 100, height: 100)), named: "\(platform)-fixed")
    await assertSnapshot(of: view, as: .image(layout: .sizeThatFits), named: "\(platform)-size-that-fits")
    await assertSnapshot(of: view, as: .image(layout: .device(config: .tv)), named: "\(platform)-device")
  }
  #endif
}
#endif
