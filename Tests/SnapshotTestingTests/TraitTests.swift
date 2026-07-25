import XCTest

@testable import SnapshotTesting

#if canImport(UIKit)
import UIKit
#endif

final class TraitTests: BaseTestCase {
  func testTraits() async {
    #if os(iOS) || os(tvOS)
    if #available(iOS 11.0, tvOS 11.0, *) {
      let viewController = TraitsViewController()

      #if os(iOS)
      await assertSnapshot(of: viewController, as: .image(on: .iPhoneSe), named: "iphone-se")
      await assertSnapshot(of: viewController, as: .image(on: .iPhone8), named: "iphone-8")
      await assertSnapshot(of: viewController, as: .image(on: .iPhone8Plus), named: "iphone-8-plus")
      await assertSnapshot(of: viewController, as: .image(on: .iPhoneX), named: "iphone-x")
      await assertSnapshot(of: viewController, as: .image(on: .iPhoneXr), named: "iphone-xr")
      await assertSnapshot(of: viewController, as: .image(on: .iPhoneXsMax), named: "iphone-xs-max")
      await assertSnapshot(of: viewController, as: .image(on: .iPadMini), named: "ipad-mini")
      await assertSnapshot(of: viewController, as: .image(on: .iPad9_7), named: "ipad-9-7")
      await assertSnapshot(of: viewController, as: .image(on: .iPad10_2), named: "ipad-10-2")
      await assertSnapshot(of: viewController, as: .image(on: .iPadPro10_5), named: "ipad-pro-10-5")
      await assertSnapshot(of: viewController, as: .image(on: .iPadPro11), named: "ipad-pro-11")
      await assertSnapshot(of: viewController, as: .image(on: .iPadPro12_9), named: "ipad-pro-12-9")

      await assertSnapshot(
        of: viewController,
        as: .recursiveDescription(on: .iPhoneSe),
        named: "iphone-se"
      )
      await assertSnapshot(
        of: viewController,
        as: .recursiveDescription(on: .iPhone8),
        named: "iphone-8"
      )
      await assertSnapshot(
        of: viewController,
        as: .recursiveDescription(on: .iPhone8Plus),
        named: "iphone-8-plus"
      )
      await assertSnapshot(
        of: viewController,
        as: .recursiveDescription(on: .iPhoneX),
        named: "iphone-x"
      )
      await assertSnapshot(
        of: viewController,
        as: .recursiveDescription(on: .iPhoneXr),
        named: "iphone-xr"
      )
      await assertSnapshot(
        of: viewController,
        as: .recursiveDescription(on: .iPhoneXsMax),
        named: "iphone-xs-max"
      )
      await assertSnapshot(
        of: viewController,
        as: .recursiveDescription(on: .iPadMini),
        named: "ipad-mini"
      )
      await assertSnapshot(
        of: viewController,
        as: .recursiveDescription(on: .iPad9_7),
        named: "ipad-9-7"
      )
      await assertSnapshot(
        of: viewController,
        as: .recursiveDescription(on: .iPad10_2),
        named: "ipad-10-2"
      )
      await assertSnapshot(
        of: viewController,
        as: .recursiveDescription(on: .iPadPro10_5),
        named: "ipad-pro-10-5"
      )
      await assertSnapshot(
        of: viewController,
        as: .recursiveDescription(on: .iPadPro11),
        named: "ipad-pro-11"
      )
      await assertSnapshot(
        of: viewController,
        as: .recursiveDescription(on: .iPadPro12_9),
        named: "ipad-pro-12-9"
      )

      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPhoneSe(.portrait)),
        named: "iphone-se"
      )
      await assertSnapshot(of: viewController, as: .image(on: .iPhone8(.portrait)), named: "iphone-8")
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPhone8Plus(.portrait)),
        named: "iphone-8-plus"
      )
      await assertSnapshot(of: viewController, as: .image(on: .iPhoneX(.portrait)), named: "iphone-x")
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPhoneXr(.portrait)),
        named: "iphone-xr"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPhoneXsMax(.portrait)),
        named: "iphone-xs-max"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPadMini(.landscape)),
        named: "ipad-mini"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPad9_7(.landscape)),
        named: "ipad-9-7"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPad10_2(.landscape)),
        named: "ipad-10-2"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPadPro10_5(.landscape)),
        named: "ipad-pro-10-5"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPadPro11(.landscape)),
        named: "ipad-pro-11"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPadPro12_9(.landscape)),
        named: "ipad-pro-12-9"
      )

      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPadMini(.landscape(splitView: .oneThird))),
        named: "ipad-mini-33-split-landscape"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPadMini(.landscape(splitView: .oneHalf))),
        named: "ipad-mini-50-split-landscape"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPadMini(.landscape(splitView: .twoThirds))),
        named: "ipad-mini-66-split-landscape"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPadMini(.portrait(splitView: .oneThird))),
        named: "ipad-mini-33-split-portrait"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPadMini(.portrait(splitView: .twoThirds))),
        named: "ipad-mini-66-split-portrait"
      )

      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPad9_7(.landscape(splitView: .oneThird))),
        named: "ipad-9-7-33-split-landscape"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPad9_7(.landscape(splitView: .oneHalf))),
        named: "ipad-9-7-50-split-landscape"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPad9_7(.landscape(splitView: .twoThirds))),
        named: "ipad-9-7-66-split-landscape"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPad9_7(.portrait(splitView: .oneThird))),
        named: "ipad-9-7-33-split-portrait"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPad9_7(.portrait(splitView: .twoThirds))),
        named: "ipad-9-7-66-split-portrait"
      )

      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPad10_2(.landscape(splitView: .oneThird))),
        named: "ipad-10-2-split-landscape"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPad10_2(.landscape(splitView: .oneHalf))),
        named: "ipad-10-2-50-split-landscape"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPad10_2(.landscape(splitView: .twoThirds))),
        named: "ipad-10-2-66-split-landscape"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPad10_2(.portrait(splitView: .oneThird))),
        named: "ipad-10-2-33-split-portrait"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPad10_2(.portrait(splitView: .twoThirds))),
        named: "ipad-10-2-66-split-portrait"
      )

      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPadPro10_5(.landscape(splitView: .oneThird))),
        named: "ipad-pro-10inch-33-split-landscape"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPadPro10_5(.landscape(splitView: .oneHalf))),
        named: "ipad-pro-10inch-50-split-landscape"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPadPro10_5(.landscape(splitView: .twoThirds))),
        named: "ipad-pro-10inch-66-split-landscape"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPadPro10_5(.portrait(splitView: .oneThird))),
        named: "ipad-pro-10inch-33-split-portrait"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPadPro10_5(.portrait(splitView: .twoThirds))),
        named: "ipad-pro-10inch-66-split-portrait"
      )

      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPadPro11(.landscape(splitView: .oneThird))),
        named: "ipad-pro-11inch-33-split-landscape"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPadPro11(.landscape(splitView: .oneHalf))),
        named: "ipad-pro-11inch-50-split-landscape"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPadPro11(.landscape(splitView: .twoThirds))),
        named: "ipad-pro-11inch-66-split-landscape"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPadPro11(.portrait(splitView: .oneThird))),
        named: "ipad-pro-11inch-33-split-portrait"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPadPro11(.portrait(splitView: .twoThirds))),
        named: "ipad-pro-11inch-66-split-portrait"
      )

      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPadPro12_9(.landscape(splitView: .oneThird))),
        named: "ipad-pro-12inch-33-split-landscape"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPadPro12_9(.landscape(splitView: .oneHalf))),
        named: "ipad-pro-12inch-50-split-landscape"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPadPro12_9(.landscape(splitView: .twoThirds))),
        named: "ipad-pro-12inch-66-split-landscape"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPadPro12_9(.portrait(splitView: .oneThird))),
        named: "ipad-pro-12inch-33-split-portrait"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPadPro12_9(.portrait(splitView: .twoThirds))),
        named: "ipad-pro-12inch-66-split-portrait"
      )

      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPhoneSe(.landscape)),
        named: "iphone-se-alternative"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPhone8(.landscape)),
        named: "iphone-8-alternative"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPhone8Plus(.landscape)),
        named: "iphone-8-plus-alternative"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPhoneX(.landscape)),
        named: "iphone-x-alternative"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPhoneXr(.landscape)),
        named: "iphone-xr-alternative"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPhoneXsMax(.landscape)),
        named: "iphone-xs-max-alternative"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPadMini(.portrait)),
        named: "ipad-mini-alternative"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPad9_7(.portrait)),
        named: "ipad-9-7-alternative"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPad10_2(.portrait)),
        named: "ipad-10-2-alternative"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPadPro10_5(.portrait)),
        named: "ipad-pro-10-5-alternative"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPadPro11(.portrait)),
        named: "ipad-pro-11-alternative"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPadPro12_9(.portrait)),
        named: "ipad-pro-12-9-alternative"
      )

      for (name, contentSize) in allContentSizes {
        await assertSnapshot(
          of: viewController,
          as: .image(on: .iPhoneSe, traits: { $0.preferredContentSizeCategory = contentSize }),
          named: "iphone-se-\(name)"
        )
      }
      #elseif os(tvOS)
      await assertSnapshot(
        of: viewController,
        as: .image(on: .tv),
        named: "tv"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .tv4K),
        named: "tv4k"
      )
      #endif
    }
    #endif
  }

  func testTraitsEmbeddedInTabNavigation() async {
    #if os(iOS)
    if #available(iOS 11.0, *) {
      let myViewController = TraitsViewController()
      let navController = UINavigationController(rootViewController: myViewController)
      let viewController = UITabBarController()
      viewController.setViewControllers([navController], animated: false)

      await assertSnapshot(of: viewController, as: .image(on: .iPhoneSe), named: "iphone-se")
      await assertSnapshot(of: viewController, as: .image(on: .iPhone8), named: "iphone-8")
      await assertSnapshot(of: viewController, as: .image(on: .iPhone8Plus), named: "iphone-8-plus")
      await assertSnapshot(of: viewController, as: .image(on: .iPhoneX), named: "iphone-x")
      await assertSnapshot(of: viewController, as: .image(on: .iPhoneXr), named: "iphone-xr")
      await assertSnapshot(of: viewController, as: .image(on: .iPhoneXsMax), named: "iphone-xs-max")
      await assertSnapshot(of: viewController, as: .image(on: .iPadMini), named: "ipad-mini")
      await assertSnapshot(of: viewController, as: .image(on: .iPad9_7), named: "ipad-9-7")
      await assertSnapshot(of: viewController, as: .image(on: .iPad10_2), named: "ipad-10-2")
      await assertSnapshot(of: viewController, as: .image(on: .iPadPro10_5), named: "ipad-pro-10-5")
      await assertSnapshot(of: viewController, as: .image(on: .iPadPro11), named: "ipad-pro-11")
      await assertSnapshot(of: viewController, as: .image(on: .iPadPro12_9), named: "ipad-pro-12-9")

      await assertSnapshot(of: viewController, as: .image(on: .iPhoneSe(.portrait)), named: "iphone-se")
      await assertSnapshot(of: viewController, as: .image(on: .iPhone8(.portrait)), named: "iphone-8")
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPhone8Plus(.portrait)),
        named: "iphone-8-plus"
      )
      await assertSnapshot(of: viewController, as: .image(on: .iPhoneX(.portrait)), named: "iphone-x")
      await assertSnapshot(of: viewController, as: .image(on: .iPhoneXr(.portrait)), named: "iphone-xr")
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPhoneXsMax(.portrait)),
        named: "iphone-xs-max"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPadMini(.landscape)),
        named: "ipad-mini"
      )
      await assertSnapshot(of: viewController, as: .image(on: .iPad9_7(.landscape)), named: "ipad-9-7")
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPad10_2(.landscape)),
        named: "ipad-10-2"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPadPro10_5(.landscape)),
        named: "ipad-pro-10-5"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPadPro11(.landscape)),
        named: "ipad-pro-11"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPadPro12_9(.landscape)),
        named: "ipad-pro-12-9"
      )

      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPhoneSe(.landscape)),
        named: "iphone-se-alternative"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPhone8(.landscape)),
        named: "iphone-8-alternative"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPhone8Plus(.landscape)),
        named: "iphone-8-plus-alternative"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPhoneX(.landscape)),
        named: "iphone-x-alternative"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPhoneXr(.landscape)),
        named: "iphone-xr-alternative"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPhoneXsMax(.landscape)),
        named: "iphone-xs-max-alternative"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPadMini(.portrait)),
        named: "ipad-mini-alternative"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPad9_7(.portrait)),
        named: "ipad-9-7-alternative"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPad10_2(.portrait)),
        named: "ipad-10-2-alternative"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPadPro10_5(.portrait)),
        named: "ipad-pro-10-5-alternative"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPadPro11(.portrait)),
        named: "ipad-pro-11-alternative"
      )
      await assertSnapshot(
        of: viewController,
        as: .image(on: .iPadPro12_9(.portrait)),
        named: "ipad-pro-12-9-alternative"
      )
    }
    #endif
  }

  func testTraitsWithView() async {
    #if os(iOS)
    if #available(iOS 11.0, *) {
      let label = UILabel()
      label.font = .preferredFont(forTextStyle: .title1)
      label.adjustsFontForContentSizeCategory = true
      label.text = "What's the point?"

      for (name, contentSize) in allContentSizes {
        await assertSnapshot(
          of: label,
          as: .image(traits: { $0.preferredContentSizeCategory = contentSize }),
          named: "label-\(name)"
        )
      }
    }
    #endif
  }

  func testTraitsWithViewController() async {
    #if os(iOS)
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .title1)
    label.adjustsFontForContentSizeCategory = true
    label.text = "What's the point?"

    let viewController = UIViewController()
    viewController.view.addSubview(label)

    label.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(
        equalTo: viewController.view.layoutMarginsGuide.leadingAnchor
      ),
      label.topAnchor.constraint(equalTo: viewController.view.layoutMarginsGuide.topAnchor),
      label.trailingAnchor.constraint(
        equalTo: viewController.view.layoutMarginsGuide.trailingAnchor
      )
    ])

    for (name, contentSize) in allContentSizes {
      await assertSnapshot(
        of: viewController,
        as: .recursiveDescription(
          on: .iPhoneSe,
          traits: { $0.preferredContentSizeCategory = contentSize }
        ),
        named: "label-\(name)"
      )
    }
    #endif
  }
}

#if os(iOS) || os(tvOS)
private final class TraitsViewController: UIViewController {
  let topLabel = UILabel()
  let leadingLabel = UILabel()
  let trailingLabel = UILabel()
  let bottomLabel = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.navigationItem.leftBarButtonItem = .init(
      barButtonSystemItem: .add,
      target: nil,
      action: nil
    )

    self.view.backgroundColor = .white

    self.topLabel.text = "What's"
    self.leadingLabel.text = "the"
    self.trailingLabel.text = "point"
    self.bottomLabel.text = "?"

    self.topLabel.translatesAutoresizingMaskIntoConstraints = false
    self.leadingLabel.translatesAutoresizingMaskIntoConstraints = false
    self.trailingLabel.translatesAutoresizingMaskIntoConstraints = false
    self.bottomLabel.translatesAutoresizingMaskIntoConstraints = false

    self.view.addSubview(self.topLabel)
    self.view.addSubview(self.leadingLabel)
    self.view.addSubview(self.trailingLabel)
    self.view.addSubview(self.bottomLabel)

    NSLayoutConstraint.activate([
      self.topLabel.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
      self.topLabel.centerXAnchor.constraint(
        equalTo: self.view.safeAreaLayoutGuide.centerXAnchor
      ),
      self.leadingLabel.leadingAnchor.constraint(
        equalTo: self.view.safeAreaLayoutGuide.leadingAnchor
      ),
      self.leadingLabel.trailingAnchor.constraint(
        lessThanOrEqualTo: self.view.safeAreaLayoutGuide.centerXAnchor
      ),
      //            self.leadingLabel.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor),
      self.leadingLabel.centerYAnchor.constraint(
        equalTo: self.view.safeAreaLayoutGuide.centerYAnchor
      ),
      self.trailingLabel.leadingAnchor.constraint(
        greaterThanOrEqualTo: self.view.safeAreaLayoutGuide.centerXAnchor
      ),
      self.trailingLabel.trailingAnchor.constraint(
        equalTo: self.view.safeAreaLayoutGuide.trailingAnchor
      ),
      self.trailingLabel.centerYAnchor.constraint(
        equalTo: self.view.safeAreaLayoutGuide.centerYAnchor
      ),
      self.bottomLabel.bottomAnchor.constraint(
        equalTo: self.view.safeAreaLayoutGuide.bottomAnchor
      ),
      self.bottomLabel.centerXAnchor.constraint(
        equalTo: self.view.safeAreaLayoutGuide.centerXAnchor
      )
    ])

    self.updateFonts()
    self.registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) {
      (self: Self, _: UITraitCollection) in
      self.updateFonts()
    }
  }

  func updateFonts() {
    self.topLabel.font = .preferredFont(
      forTextStyle: .headline,
      compatibleWith: self.traitCollection
    )
    self.leadingLabel.font = .preferredFont(
      forTextStyle: .body,
      compatibleWith: self.traitCollection
    )
    self.trailingLabel.font = .preferredFont(
      forTextStyle: .body,
      compatibleWith: self.traitCollection
    )
    self.bottomLabel.font = .preferredFont(
      forTextStyle: .subheadline,
      compatibleWith: self.traitCollection
    )
    self.view.setNeedsUpdateConstraints()
    self.view.updateConstraintsIfNeeded()
  }
}
#endif

#if os(iOS)
private let allContentSizes =
  [
    "extra-small": UIContentSizeCategory.extraSmall,
    "small": .small,
    "medium": .medium,
    "large": .large,
    "extra-large": .extraLarge,
    "extra-extra-large": .extraExtraLarge,
    "extra-extra-extra-large": .extraExtraExtraLarge,
    "accessibility-medium": .accessibilityMedium,
    "accessibility-large": .accessibilityLarge,
    "accessibility-extra-large": .accessibilityExtraLarge,
    "accessibility-extra-extra-large": .accessibilityExtraExtraLarge,
    "accessibility-extra-extra-extra-large": .accessibilityExtraExtraExtraLarge
  ]
#endif
