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
      named: "\(platform)-fixed"
    )
    await expectSnapshot(
      of: view,
      as: .image(layout: .sizeThatFits, traits: { $0.userInterfaceStyle = .light }),
      named: "\(platform)-size-that-fits"
    )
    await expectSnapshot(
      of: view,
      as: .image(layout: .device(profile: .iPhoneSe), traits: { $0.userInterfaceStyle = .light }),
      named: "\(platform)-device"
    )
    #endif

    #if os(macOS)
    await expectSnapshot(
      of: view,
      as: .image(layout: .fixed(width: 100, height: 100)),
      named: "\(platform)\(osVersion.majorVersion)-fixed"
    )
    await expectSnapshot(
      of: view,
      as: .image(layout: .sizeThatFits),
      named: "\(platform)\(osVersion.majorVersion)-size-that-fits"
    )
    #endif

    #if os(tvOS)
    await expectSnapshot(
      of: view,
      as: .image(layout: .fixed(width: 100, height: 100)),
      named: "\(platform)-fixed"
    )
    await expectSnapshot(
      of: view,
      as: .image(layout: .sizeThatFits),
      named: "\(platform)-size-that-fits"
    )
    await expectSnapshot(
      of: view,
      as: .image(layout: .device(profile: .tv)),
      named: "\(platform)-device"
    )
    #endif
  }
}
#endif
