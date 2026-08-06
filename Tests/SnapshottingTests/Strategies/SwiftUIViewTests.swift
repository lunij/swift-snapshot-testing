#if canImport(SwiftUI)
import Snapshotting
import SwiftUI
import Testing

struct SwiftUIViewTests {
  struct SwiftUIView: View {
    var body: some View {
      ZStack {
        Color.green
        Color.yellow.padding()
        Color.red.frame(minWidth: 5, minHeight: 5).padding().padding()
      }
    }
  }

  @Test func `SwiftUI View`() async {
    let view = SwiftUIView()

    #if os(iOS)
    await expectSnapshot(
      of: view,
      as: .image(
        layout: .fixed(width: 100, height: 100),
        traits: { $0.userInterfaceStyle = .light }
      ),
      suffixed: "fixed"
    )
    await expectSnapshot(
      of: view,
      as: .image(layout: .sizeThatFits, traits: { $0.userInterfaceStyle = .light }),
      suffixed: "size-that-fits"
    )
    await expectSnapshot(
      of: view,
      as: .image(layout: .device(profile: .iPhone(.year2014)), traits: { $0.userInterfaceStyle = .light }),
      suffixed: "device"
    )
    #endif

    #if os(macOS)
    await expectSnapshot(
      of: view,
      as: .image(layout: .fixed(width: 100, height: 100)),
      suffixed: "fixed"
    )
    await expectSnapshot(
      of: view,
      as: .image(layout: .sizeThatFits),
      suffixed: "size-that-fits"
    )
    #endif

    #if os(tvOS)
    await expectSnapshot(
      of: view,
      as: .image(layout: .fixed(width: 100, height: 100)),
      suffixed: "fixed"
    )
    await expectSnapshot(
      of: view,
      as: .image(layout: .sizeThatFits),
      suffixed: "size-that-fits"
    )
    await expectSnapshot(
      of: view,
      as: .image(layout: .device(profile: .appleTV)),
      suffixed: "device"
    )
    #endif
  }
}
#endif
