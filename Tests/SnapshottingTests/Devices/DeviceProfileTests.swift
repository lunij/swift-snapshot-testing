#if os(iOS)
import Snapshotting
import Testing
import UIKit

/// Pins the geometry each device family reports. Rendered output for a handful of these profiles is
/// covered by `TraitTests`; this covers the tables themselves, including the screens no installed
/// simulator can render.
@MainActor
struct DeviceProfileTests {

  // MARK: - iPhone

  @Test(
    arguments: [
      (DeviceProfile.PhoneGeneration.year2012, CGSize(width: 320, height: 568)),
      (.year2014, CGSize(width: 375, height: 667)),
      (.year2014Plus, CGSize(width: 414, height: 736)),
      (.year2017, CGSize(width: 375, height: 812)),
      (.year2018, CGSize(width: 414, height: 896)),
      (.year2020Mini, CGSize(width: 375, height: 812)),
      (.year2020, CGSize(width: 390, height: 844)),
      (.year2020Max, CGSize(width: 428, height: 926)),
      (.year2022, CGSize(width: 393, height: 852)),
      (.year2022Max, CGSize(width: 430, height: 932)),
      (.year2024, CGSize(width: 402, height: 874)),
      (.year2024Max, CGSize(width: 440, height: 956)),
      (.year2025Air, CGSize(width: 420, height: 912))
    ]
  )
  func `a phone is its portrait size, transposed in landscape`(
    generation: DeviceProfile.PhoneGeneration,
    portraitSize: CGSize
  ) {
    #expect(DeviceProfile.iPhone(generation).size == portraitSize)
    #expect(
      DeviceProfile.iPhone(generation, .landscape).size
        == CGSize(width: portraitSize.height, height: portraitSize.width)
    )
  }

  @Test func `the screens added in 2022 reserve nothing at the top in landscape`() {
    #expect(
      DeviceProfile.iPhone(.year2022).safeArea
        == UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0)
    )
    #expect(
      DeviceProfile.iPhone(.year2022, .landscape).safeArea
        == UIEdgeInsets(top: 0, left: 59, bottom: 21, right: 59)
    )
  }

  @Test func `the screens added in 2024 reserve 20 points at the top in landscape`() {
    #expect(
      DeviceProfile.iPhone(.year2024).safeArea
        == UIEdgeInsets(top: 62, left: 0, bottom: 34, right: 0)
    )
    #expect(
      DeviceProfile.iPhone(.year2024, .landscape).safeArea
        == UIEdgeInsets(top: 20, left: 62, bottom: 20, right: 62)
    )
  }

  @Test func `the iPhone Air stands alone`() {
    #expect(
      DeviceProfile.iPhone(.year2025Air).safeArea
        == UIEdgeInsets(top: 68, left: 0, bottom: 34, right: 0)
    )
    #expect(
      DeviceProfile.iPhone(.year2025Air, .landscape).safeArea
        == UIEdgeInsets(top: 20, left: 68, bottom: 29, right: 68)
    )
  }

  @Test func `a phone is horizontally compact in portrait`() {
    #expect(DeviceProfile.iPhone(.year2024).traitCollection.horizontalSizeClass == .compact)
    #expect(DeviceProfile.iPhone(.year2024).traitCollection.verticalSizeClass == .regular)
    #expect(DeviceProfile.iPhone(.year2024).traitCollection.userInterfaceIdiom == .phone)
  }

  @Test func `only the largest phones are horizontally regular in landscape`() {
    let compact: [DeviceProfile.PhoneGeneration] = [.year2022, .year2024]
    let regular: [DeviceProfile.PhoneGeneration] = [.year2022Max, .year2024Max, .year2025Air]
    for generation in compact {
      #expect(
        DeviceProfile.iPhone(generation, .landscape).traitCollection.horizontalSizeClass == .compact,
        "\(generation)"
      )
    }
    for generation in regular {
      #expect(
        DeviceProfile.iPhone(generation, .landscape).traitCollection.horizontalSizeClass == .regular,
        "\(generation)"
      )
    }
  }

  // MARK: - iPad

  @Test(
    arguments: [
      (DeviceProfile.TabletGeneration.year2010, CGSize(width: 1024, height: 768)),
      (.year2015, CGSize(width: 1366, height: 1024)),
      (.year2017, CGSize(width: 1112, height: 834)),
      (.year2018, CGSize(width: 1194, height: 834)),
      (.year2019, CGSize(width: 1080, height: 810))
    ]
  )
  func `a tablet is its landscape size, transposed in portrait`(
    generation: DeviceProfile.TabletGeneration,
    landscapeSize: CGSize
  ) {
    #expect(DeviceProfile.iPad(generation).size == landscapeSize)
    #expect(
      DeviceProfile.iPad(generation, .portrait).size
        == CGSize(width: landscapeSize.height, height: landscapeSize.width)
    )
  }

  @Test func `a tablet is regular in both dimensions`() {
    #expect(DeviceProfile.iPad(.year2010).traitCollection.horizontalSizeClass == .regular)
    #expect(DeviceProfile.iPad(.year2010).traitCollection.verticalSizeClass == .regular)
    #expect(DeviceProfile.iPad(.year2010).traitCollection.userInterfaceIdiom == .pad)
  }

  // MARK: - Windows

  @Test func `a window keeps the height and the insets of its screen`() {
    let screen = DeviceProfile.iPad(.year2015)
    let window = screen.windowed(width: 375)
    #expect(window.size == CGSize(width: 375, height: 1024))
    #expect(window.safeArea == screen.safeArea)
    #expect(window.scale == screen.scale)
    #expect(window.traitCollection.userInterfaceIdiom == .pad)
  }

  @Test(arguments: [320, 375, 438, 507, 592, 639])
  func `a window narrower than 640 points is horizontally compact`(width: CGFloat) {
    #expect(
      DeviceProfile.iPad(.year2015).windowed(width: width)
        .traitCollection.horizontalSizeClass == .compact,
      "\(width)"
    )
  }

  @Test(arguments: [640, 678, 694, 782, 981])
  func `a window 640 points across or wider is horizontally regular`(width: CGFloat) {
    #expect(
      DeviceProfile.iPad(.year2015).windowed(width: width)
        .traitCollection.horizontalSizeClass == .regular,
      "\(width)"
    )
  }
}

extension DeviceProfile {
  fileprivate var traitCollection: UITraitCollection {
    UITraitCollection(mutations: traits)
  }
}
#endif
