#if os(iOS) || os(tvOS)
import Snapshotting
import Testing
import UIKit

/// Pins the geometry each device family reports. Rendered output for a handful of these profiles is
/// covered by `TraitTests`; this covers the tables themselves, including the screens no installed
/// simulator can render.
@MainActor
struct DeviceProfileTests {
  #if os(iOS)

  // MARK: - iPhone

  @Test(
    arguments: [
      (DeviceProfile.PhoneGeneration.year2014, CGSize(width: 375, height: 667)),
      (.year2017, CGSize(width: 375, height: 812)),
      (.year2018, CGSize(width: 414, height: 896)),
      (.year2018Max, CGSize(width: 414, height: 896)),
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

  @Test func `a phone a home button frames reserves only the status bar`() {
    #expect(
      DeviceProfile.iPhone(.year2014).safeArea
        == UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
    )
    #expect(DeviceProfile.iPhone(.year2014, .landscape).safeArea == .zero)
  }

  /// A sensor housing reaches into the top of the screen in portrait, and into each side in
  /// landscape, where the system leaves the top free.
  @Test(
    arguments: [
      (DeviceProfile.PhoneGeneration.year2017, CGFloat(44)),
      (.year2018, 48),
      (.year2018Max, 44),
      (.year2020Mini, 50),
      (.year2020, 47),
      (.year2020Max, 47),
      (.year2022, 59),
      (.year2022Max, 59),
      (.year2024, 62),
      (.year2024Max, 62),
      (.year2025Air, 68)
    ]
  )
  func `a phone reserves its sensor housing at the top in portrait and at the sides in landscape`(
    generation: DeviceProfile.PhoneGeneration,
    housing: CGFloat
  ) {
    #expect(
      DeviceProfile.iPhone(generation).safeArea
        == UIEdgeInsets(top: housing, left: 0, bottom: 34, right: 0)
    )
    let landscape = DeviceProfile.iPhone(generation, .landscape).safeArea
    #expect(landscape.top == 0)
    #expect(landscape.left == housing)
    #expect(landscape.right == housing)
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

  /// The two 414 × 896 families differ only in the chrome around them: the @2x screen reserves 48
  /// points for its sensor housing where the @3x screen reserves 44.
  @Test func `the 2018 max phone matches the 2018 one but for its insets`() {
    #expect(DeviceProfile.iPhone(.year2018Max).size == DeviceProfile.iPhone(.year2018).size)
    #expect(DeviceProfile.iPhone(.year2018Max).safeArea != DeviceProfile.iPhone(.year2018).safeArea)
  }

  // MARK: - iPad

  @Test(
    arguments: [
      (DeviceProfile.TabletGeneration.year2010, CGSize(width: 1024, height: 768)),
      (.year2017, CGSize(width: 1112, height: 834)),
      (.year2018, CGSize(width: 1194, height: 834)),
      (.year2018Large, CGSize(width: 1366, height: 1024)),
      (.year2019, CGSize(width: 1080, height: 810)),
      (.year2020, CGSize(width: 1180, height: 820)),
      (.year2021, CGSize(width: 1133, height: 744)),
      (.year2024, CGSize(width: 1210, height: 834)),
      (.year2024Large, CGSize(width: 1376, height: 1032))
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

  @Test func `a tablet reserves the same insets in either orientation`() {
    for generation in [DeviceProfile.TabletGeneration.year2010, .year2018] {
      #expect(
        DeviceProfile.iPad(generation).safeArea
          == DeviceProfile.iPad(generation, .portrait).safeArea,
        "\(generation)"
      )
    }
  }

  @Test func `a tablet a home button frames reserves only the status bar`() {
    for generation in [DeviceProfile.TabletGeneration.year2010, .year2017, .year2019] {
      #expect(
        DeviceProfile.iPad(generation).safeArea
          == UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0),
        "\(generation)"
      )
    }
  }

  @Test func `a tablet with a home indicator reserves room below the screen`() {
    let generations: [DeviceProfile.TabletGeneration] = [
      .year2018, .year2018Large, .year2020, .year2021, .year2024, .year2024Large
    ]
    for generation in generations {
      #expect(DeviceProfile.iPad(generation).safeArea.bottom == 25, "\(generation)")
    }
  }

  // MARK: - The running system

  /// The insets belong to the system, not to the screen: iOS 26 draws a deeper status bar on an
  /// iPad, and a slimmer landscape home indicator on an iPhone, than earlier releases do.
  @Test func `the running system decides how deep the chrome is`() {
    let tabletStatusBar = DeviceProfile.iPad(.year2018).safeArea.top
    let phoneHomeIndicator = DeviceProfile.iPhone(.year2024, .landscape).safeArea.bottom
    if #available(iOS 26, *) {
      #expect(tabletStatusBar == 32)
      #expect(phoneHomeIndicator == 20)
    } else {
      #expect(tabletStatusBar == 24)
      #expect(phoneHomeIndicator == 21)
    }
    #expect(DeviceProfile.iPad(.year2018).safeArea.bottom == 25)
  }

  // MARK: - Windows

  @Test func `a window keeps the height and the insets of its screen`() {
    let screen = DeviceProfile.iPad(.year2018Large)
    let window = screen.windowed(width: 375)
    #expect(window.size == CGSize(width: 375, height: 1024))
    #expect(window.safeArea == screen.safeArea)
    #expect(window.traitCollection.userInterfaceIdiom == .pad)
  }

  @Test(arguments: [320, 375, 438, 507, 592, 639])
  func `a window narrower than 640 points is horizontally compact`(width: CGFloat) {
    #expect(
      DeviceProfile.iPad(.year2018Large).windowed(width: width)
        .traitCollection.horizontalSizeClass == .compact,
      "\(width)"
    )
  }

  @Test(arguments: [640, 678, 694, 782, 981])
  func `a window 640 points across or wider is horizontally regular`(width: CGFloat) {
    #expect(
      DeviceProfile.iPad(.year2018Large).windowed(width: width)
        .traitCollection.horizontalSizeClass == .regular,
      "\(width)"
    )
  }
  #elseif os(tvOS)

  // MARK: - Apple TV

  /// The values tvOS itself reports, measured on `UIScreen.main` and on a hosted window rather than
  /// read off a published table. Every Apple TV agrees on them — the HD model, the 4K model, and a
  /// 4K set to output 1080p — which is why one profile covers the family.
  @Test func `a tv is 1920 by 1080 points`() {
    #expect(DeviceProfile.appleTV.size == CGSize(width: 1920, height: 1080))
  }

  /// The overscan margin a television reserves on all four edges, deeper at the sides than at the
  /// top and bottom. Not to be confused with the layout margins, which tvOS draws at 96 points
  /// across.
  @Test func `a tv reserves its overscan margin on every edge`() {
    #expect(
      DeviceProfile.appleTV.safeArea == UIEdgeInsets(top: 60, left: 80, bottom: 60, right: 80)
    )
  }

  @Test func `a tv is regular in both dimensions`() {
    #expect(DeviceProfile.appleTV.traitCollection.userInterfaceIdiom == .tv)
    #expect(DeviceProfile.appleTV.traitCollection.horizontalSizeClass == .regular)
    #expect(DeviceProfile.appleTV.traitCollection.verticalSizeClass == .regular)
  }
  #endif
}

extension DeviceProfile {
  fileprivate var traitCollection: UITraitCollection {
    UITraitCollection(mutations: traits)
  }
}
#endif
