#if os(iOS) || os(tvOS)
import Snapshotting
import Testing

#if canImport(UIKit)
import UIKit
#endif

@MainActor
struct TraitTests {
  @Test func `traits`() async {
    let vc = TraitsViewController()

    #if os(iOS)
    await expectSnapshot(of: vc, as: .image(on: .iPhone(.year2012)), named: "iphone-se")
    await expectSnapshot(of: vc, as: .image(on: .iPhone(.year2014)), named: "iphone-8")
    await expectSnapshot(of: vc, as: .image(on: .iPhone(.year2014Plus)), named: "iphone-8-plus")
    await expectSnapshot(of: vc, as: .image(on: .iPhone(.year2017)), named: "iphone-x")
    await expectSnapshot(of: vc, as: .image(on: .iPhone(.year2018)), named: "iphone-xs-max")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2010)), named: "ipad-mini")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2019)), named: "ipad-10-2")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2017)), named: "ipad-pro-10-5")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2018)), named: "ipad-pro-11")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2015)), named: "ipad-pro-12-9")

    await expectSnapshot(of: vc, as: .recursiveDescription(on: .iPhone(.year2012)), named: "iphone-se")
    await expectSnapshot(of: vc, as: .recursiveDescription(on: .iPhone(.year2014)), named: "iphone-8")
    await expectSnapshot(of: vc, as: .recursiveDescription(on: .iPhone(.year2014Plus)), named: "iphone-8-plus")
    await expectSnapshot(of: vc, as: .recursiveDescription(on: .iPhone(.year2017)), named: "iphone-x")
    await expectSnapshot(of: vc, as: .recursiveDescription(on: .iPhone(.year2018)), named: "iphone-xs-max")
    await expectSnapshot(of: vc, as: .recursiveDescription(on: .iPad(.year2010)), named: "ipad-mini")
    await expectSnapshot(of: vc, as: .recursiveDescription(on: .iPad(.year2019)), named: "ipad-10-2")
    await expectSnapshot(of: vc, as: .recursiveDescription(on: .iPad(.year2017)), named: "ipad-pro-10-5")
    await expectSnapshot(of: vc, as: .recursiveDescription(on: .iPad(.year2018)), named: "ipad-pro-11")
    await expectSnapshot(of: vc, as: .recursiveDescription(on: .iPad(.year2015)), named: "ipad-pro-12-9")

    await expectSnapshot(of: vc, as: .image(on: .iPhone(.year2012, .portrait)), named: "iphone-se")
    await expectSnapshot(of: vc, as: .image(on: .iPhone(.year2014, .portrait)), named: "iphone-8")
    await expectSnapshot(of: vc, as: .image(on: .iPhone(.year2014Plus, .portrait)), named: "iphone-8-plus")
    await expectSnapshot(of: vc, as: .image(on: .iPhone(.year2017, .portrait)), named: "iphone-x")
    await expectSnapshot(of: vc, as: .image(on: .iPhone(.year2018, .portrait)), named: "iphone-xs-max")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2010, .landscape)), named: "ipad-mini")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2019, .landscape)), named: "ipad-10-2")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2017, .landscape)), named: "ipad-pro-10-5")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2018, .landscape)), named: "ipad-pro-11")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2015, .landscape)), named: "ipad-pro-12-9")

    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2010, .landscape(splitView: .oneThird))), named: "ipad-mini-33-split-landscape")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2010, .landscape(splitView: .oneHalf))), named: "ipad-mini-50-split-landscape")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2010, .landscape(splitView: .twoThirds))), named: "ipad-mini-66-split-landscape")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2010, .portrait(splitView: .oneThird))), named: "ipad-mini-33-split-portrait")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2010, .portrait(splitView: .twoThirds))), named: "ipad-mini-66-split-portrait")

    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2019, .landscape(splitView: .oneThird))), named: "ipad-10-2-split-landscape")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2019, .landscape(splitView: .oneHalf))), named: "ipad-10-2-50-split-landscape")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2019, .landscape(splitView: .twoThirds))), named: "ipad-10-2-66-split-landscape")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2019, .portrait(splitView: .oneThird))), named: "ipad-10-2-33-split-portrait")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2019, .portrait(splitView: .twoThirds))), named: "ipad-10-2-66-split-portrait")

    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2017, .landscape(splitView: .oneThird))), named: "ipad-pro-10inch-33-split-landscape")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2017, .landscape(splitView: .oneHalf))), named: "ipad-pro-10inch-50-split-landscape")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2017, .landscape(splitView: .twoThirds))), named: "ipad-pro-10inch-66-split-landscape")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2017, .portrait(splitView: .oneThird))), named: "ipad-pro-10inch-33-split-portrait")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2017, .portrait(splitView: .twoThirds))), named: "ipad-pro-10inch-66-split-portrait")

    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2018, .landscape(splitView: .oneThird))), named: "ipad-pro-11inch-33-split-landscape")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2018, .landscape(splitView: .oneHalf))), named: "ipad-pro-11inch-50-split-landscape")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2018, .landscape(splitView: .twoThirds))), named: "ipad-pro-11inch-66-split-landscape")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2018, .portrait(splitView: .oneThird))), named: "ipad-pro-11inch-33-split-portrait")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2018, .portrait(splitView: .twoThirds))), named: "ipad-pro-11inch-66-split-portrait")

    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2015, .landscape(splitView: .oneThird))), named: "ipad-pro-12inch-33-split-landscape")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2015, .landscape(splitView: .oneHalf))), named: "ipad-pro-12inch-50-split-landscape")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2015, .landscape(splitView: .twoThirds))), named: "ipad-pro-12inch-66-split-landscape")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2015, .portrait(splitView: .oneThird))), named: "ipad-pro-12inch-33-split-portrait")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2015, .portrait(splitView: .twoThirds))), named: "ipad-pro-12inch-66-split-portrait")

    await expectSnapshot(of: vc, as: .image(on: .iPhone(.year2012, .landscape)), named: "iphone-se-alternative")
    await expectSnapshot(of: vc, as: .image(on: .iPhone(.year2014, .landscape)), named: "iphone-8-alternative")
    await expectSnapshot(of: vc, as: .image(on: .iPhone(.year2014Plus, .landscape)), named: "iphone-8-plus-alternative")
    await expectSnapshot(of: vc, as: .image(on: .iPhone(.year2017, .landscape)), named: "iphone-x-alternative")
    await expectSnapshot(of: vc, as: .image(on: .iPhone(.year2018, .landscape)), named: "iphone-xs-max-alternative")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2010, .portrait)), named: "ipad-mini-alternative")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2019, .portrait)), named: "ipad-10-2-alternative")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2017, .portrait)), named: "ipad-pro-10-5-alternative")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2018, .portrait)), named: "ipad-pro-11-alternative")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2015, .portrait)), named: "ipad-pro-12-9-alternative")

    for (name, contentSize) in allContentSizes {
      await expectSnapshot(
        of: vc,
        as: .image(on: .iPhone(.year2012), traits: { $0.preferredContentSizeCategory = contentSize }),
        named: "iphone-se-\(name)"
      )
    }
    #elseif os(tvOS)
    await expectSnapshot(of: viewController, as: .image(on: .tv), named: "tv")
    await expectSnapshot(of: viewController, as: .image(on: .tv4K), named: "tv4k")
    #endif
  }

  #if os(iOS)
  @Test func `traits embedded in tab navigation`() async {
    let myViewController = TraitsViewController()
    let navController = UINavigationController(rootViewController: myViewController)
    let vc = UITabBarController()
    vc.setViewControllers([navController], animated: false)

    await expectSnapshot(of: vc, as: .image(on: .iPhone(.year2012)), named: "iphone-se")
    await expectSnapshot(of: vc, as: .image(on: .iPhone(.year2014)), named: "iphone-8")
    await expectSnapshot(of: vc, as: .image(on: .iPhone(.year2014Plus)), named: "iphone-8-plus")
    await expectSnapshot(of: vc, as: .image(on: .iPhone(.year2017)), named: "iphone-x")
    await expectSnapshot(of: vc, as: .image(on: .iPhone(.year2018)), named: "iphone-xs-max")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2010)), named: "ipad-mini")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2019)), named: "ipad-10-2")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2017)), named: "ipad-pro-10-5")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2018)), named: "ipad-pro-11")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2015)), named: "ipad-pro-12-9")

    await expectSnapshot(of: vc, as: .image(on: .iPhone(.year2012, .portrait)), named: "iphone-se")
    await expectSnapshot(of: vc, as: .image(on: .iPhone(.year2014, .portrait)), named: "iphone-8")
    await expectSnapshot(of: vc, as: .image(on: .iPhone(.year2014Plus, .portrait)), named: "iphone-8-plus")
    await expectSnapshot(of: vc, as: .image(on: .iPhone(.year2017, .portrait)), named: "iphone-x")
    await expectSnapshot(of: vc, as: .image(on: .iPhone(.year2018, .portrait)), named: "iphone-xs-max")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2010, .landscape)), named: "ipad-mini")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2019, .landscape)), named: "ipad-10-2")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2017, .landscape)), named: "ipad-pro-10-5")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2018, .landscape)), named: "ipad-pro-11")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2015, .landscape)), named: "ipad-pro-12-9")

    await expectSnapshot(of: vc, as: .image(on: .iPhone(.year2012, .landscape)), named: "iphone-se-alternative")
    await expectSnapshot(of: vc, as: .image(on: .iPhone(.year2014, .landscape)), named: "iphone-8-alternative")
    await expectSnapshot(of: vc, as: .image(on: .iPhone(.year2014Plus, .landscape)), named: "iphone-8-plus-alternative")
    await expectSnapshot(of: vc, as: .image(on: .iPhone(.year2017, .landscape)), named: "iphone-x-alternative")
    await expectSnapshot(of: vc, as: .image(on: .iPhone(.year2018, .landscape)), named: "iphone-xs-max-alternative")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2010, .portrait)), named: "ipad-mini-alternative")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2019, .portrait)), named: "ipad-10-2-alternative")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2017, .portrait)), named: "ipad-pro-10-5-alternative")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2018, .portrait)), named: "ipad-pro-11-alternative")
    await expectSnapshot(of: vc, as: .image(on: .iPad(.year2015, .portrait)), named: "ipad-pro-12-9-alternative")
  }

  @Test func `traits with view`() async {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .title1)
    label.adjustsFontForContentSizeCategory = true
    label.text = "What's the point?"

    for (name, contentSize) in allContentSizes {
      await expectSnapshot(
        of: label,
        as: .image(traits: { $0.preferredContentSizeCategory = contentSize }),
        named: "label-\(name)"
      )
    }
  }

  @Test func `traits with view controller`() async {
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
      await expectSnapshot(
        of: viewController,
        as: .recursiveDescription(
          on: .iPhone(.year2012),
          traits: { $0.preferredContentSizeCategory = contentSize }
        ),
        named: "label-\(name)"
      )
    }
  }
  #endif
}

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
#endif
