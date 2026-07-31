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
  func `a tablet fills the screen unless it is sharing it`(
    generation: DeviceProfile.TabletGeneration,
    landscapeSize: CGSize
  ) {
    #expect(DeviceProfile.iPad(generation).size == landscapeSize)
    #expect(
      DeviceProfile.iPad(generation, .portrait).size
        == CGSize(width: landscapeSize.height, height: landscapeSize.width)
    )
    let oneThird = DeviceProfile.iPad(generation, .landscape(splitView: .oneThird))
    #expect(oneThird.size?.width ?? 0 < landscapeSize.width)
    #expect(oneThird.size?.height == landscapeSize.height)
  }

  @Test func `a tablet is horizontally regular until a split view narrows it`() {
    #expect(DeviceProfile.iPad(.year2010).traitCollection.horizontalSizeClass == .regular)
    #expect(
      DeviceProfile.iPad(.year2010, .landscape(splitView: .oneThird))
        .traitCollection.horizontalSizeClass == .compact
    )
    #expect(DeviceProfile.iPad(.year2010).traitCollection.userInterfaceIdiom == .pad)
  }

  /// The 12.9" is the only iPad wide enough to keep both halves regular in a 50:50 landscape split.
  @Test func `only the largest tablet stays regular in a half split`() {
    #expect(
      DeviceProfile.iPad(.year2015, .landscape(splitView: .oneHalf))
        .traitCollection.horizontalSizeClass == .regular
    )
    for generation in [DeviceProfile.TabletGeneration.year2010, .year2017, .year2018, .year2019] {
      #expect(
        DeviceProfile.iPad(generation, .landscape(splitView: .oneHalf))
          .traitCollection.horizontalSizeClass == .compact,
        "\(generation)"
      )
    }
  }
}

extension DeviceProfile {
  fileprivate var traitCollection: UITraitCollection {
    UITraitCollection(mutations: traits)
  }
}
#endif
