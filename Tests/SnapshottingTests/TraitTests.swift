#if os(iOS) || os(tvOS)
import Snapshotting
import Testing
import UIKit

/// Renders a view that fills its safe area on every screen a device family describes, so that the
/// insets each one reserves are visible in a reference image.
@MainActor
struct TraitTests {
  #if os(iOS)

  // MARK: - iPhone

  @Test func `a phone renders its safe area`() async {
    for (generation, name) in phoneScreens {
      let viewController = SafeAreaViewController(caption: generation.description)
      await expectSnapshot(
        of: viewController,
        as: .image(on: .iPhone(generation, .landscape)),
        named: "\(name)-landscape"
      )
      await expectSnapshot(
        of: viewController,
        as: .image(on: .iPhone(generation, .portrait)),
        named: "\(name)-portrait"
      )
    }
  }

  @Test func `a phone reports its layout`() async {
    for (generation, name) in phoneScreens {
      let viewController = SafeAreaViewController(caption: generation.description)
      await expectSnapshot(
        of: viewController,
        as: .recursiveDescription(on: .iPhone(generation)),
        named: name
      )
    }
  }

  @Test func `a phone renders every content size`() async {
    let generation = DeviceProfile.PhoneGeneration.year2012
    for (category, name) in contentSizes {
      // The caption is two letters, not the category it renders at. An accessibility size draws body
      // text near 53pt, which leaves room for about four characters across this screen, so a longer
      // caption would have to be broken mid-word — and where a text engine chooses to break a word
      // is not stable across the systems this suite records and verifies on. The reference file is
      // named after the category; the glyphs only have to show the size it resolved to.
      let viewController = SafeAreaViewController(caption: "Aa")
      await expectSnapshot(
        of: viewController,
        as: .image(on: .iPhone(generation), traits: { $0.preferredContentSizeCategory = category }),
        named: name
      )
    }
  }

  // MARK: - iPad

  @Test func `a tablet renders its safe area`() async {
    for (generation, name) in tabletScreens {
      let viewController = SafeAreaViewController(caption: generation.description)
      await expectSnapshot(
        of: viewController,
        as: .image(on: .iPad(generation, .landscape)),
        named: "\(name)-landscape"
      )
      await expectSnapshot(
        of: viewController,
        as: .image(on: .iPad(generation, .portrait)),
        named: "\(name)-portrait"
      )
    }
  }

  @Test func `a tablet reports its layout`() async {
    for (generation, name) in tabletScreens {
      let viewController = SafeAreaViewController(caption: generation.description)
      await expectSnapshot(
        of: viewController,
        as: .recursiveDescription(on: .iPad(generation)),
        named: name
      )
    }
  }

  /// A window keeps the insets of the screen it sits on, so narrowing it moves only the side the
  /// window was trimmed on.
  @Test func `a tablet renders in a window`() async {
    for (generation, name) in tabletScreens {
      for width in windowWidths {
        // The stem names the screen rather than `generation.description`: the prose list of marketing
        // names is long enough to fill a 320pt window, which puts a line break on a knife edge that
        // different systems decide differently.
        let viewController = SafeAreaViewController(
          caption: "\(name)\n\(Int(width)) pt window"
        )
        await expectSnapshot(
          of: viewController,
          as: .image(on: .iPad(generation, .landscape).windowed(width: width)),
          named: "\(name)-\(Int(width))"
        )
      }
    }
  }

  // MARK: - Chrome the system draws

  @Test func `a tab navigation renders on every screen`() async {
    for (generation, name) in phoneScreens {
      let viewController = tabNavigation(around: generation.description)
      await expectSnapshot(
        of: viewController,
        as: .image(on: .iPhone(generation, .landscape)),
        named: "\(name)-landscape"
      )
      await expectSnapshot(
        of: viewController,
        as: .image(on: .iPhone(generation, .portrait)),
        named: "\(name)-portrait"
      )
    }
    for (generation, name) in tabletScreens {
      let viewController = tabNavigation(around: generation.description)
      await expectSnapshot(
        of: viewController,
        as: .image(on: .iPad(generation, .landscape)),
        named: "\(name)-landscape"
      )
      await expectSnapshot(
        of: viewController,
        as: .image(on: .iPad(generation, .portrait)),
        named: "\(name)-portrait"
      )
    }
  }

  /// A ``SafeAreaViewController`` under a navigation bar and above a tab bar, whose own insets add to
  /// the ones the screen reserves.
  private func tabNavigation(around caption: String) -> UITabBarController {
    let navigation = UINavigationController(rootViewController: SafeAreaViewController(caption: caption))
    let tabs = UITabBarController()
    tabs.setViewControllers([navigation], animated: false)
    return tabs
  }

  // MARK: - Dynamic Type

  /// A view carries no screen of its own, so the category is the only thing that varies: the text
  /// stays put and the type scales around it.
  @Test func `a view renders every content size`() async {
    let label = dynamicTypeLabel()

    for (category, name) in contentSizes {
      await expectSnapshot(
        of: label,
        as: .image(traits: { $0.preferredContentSizeCategory = category }),
        named: name
      )
    }
  }

  @Test func `a view controller reports its layout at every content size`() async {
    let label = dynamicTypeLabel()
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

    for (category, name) in contentSizes {
      await expectSnapshot(
        of: viewController,
        as: .recursiveDescription(
          on: .iPhone(.year2012),
          traits: { $0.preferredContentSizeCategory = category }
        ),
        named: name
      )
    }
  }

  /// A label that follows the content size category, with text that names what it is measuring.
  private func dynamicTypeLabel() -> UILabel {
    let label = UILabel()
    label.adjustsFontForContentSizeCategory = true
    label.backgroundColor = .systemBackground
    label.font = .preferredFont(forTextStyle: .title1)
    label.text = "Dynamic Type"
    return label
  }
  #elseif os(tvOS)

  // MARK: - Apple TV

  @Test func `a tv renders its safe area`() async {
    await expectSnapshot(
      of: SafeAreaViewController(caption: "DeviceProfile .tv\nApple TV HD"),
      as: .image(on: .tv),
      named: "tv"
    )
    await expectSnapshot(
      of: SafeAreaViewController(caption: "DeviceProfile .tv4K\nApple TV 4K"),
      as: .image(on: .tv4K),
      named: "tv-4k"
    )
  }
  #endif
}

// MARK: - The screens under test

#if os(iOS)
/// Every iPhone screen, in alphabetical order of the family that ships it, paired with the stem its
/// reference files are named after.
private let phoneScreens: [(generation: DeviceProfile.PhoneGeneration, name: String)] = [
  (.year2012, "iphone-2012"),
  (.year2014, "iphone-2014"),
  (.year2014Plus, "iphone-2014-plus"),
  (.year2017, "iphone-2017"),
  (.year2018, "iphone-2018"),
  (.year2018Max, "iphone-2018-max"),
  (.year2020, "iphone-2020"),
  (.year2020Max, "iphone-2020-max"),
  (.year2020Mini, "iphone-2020-mini"),
  (.year2022, "iphone-2022"),
  (.year2022Max, "iphone-2022-max"),
  (.year2024, "iphone-2024"),
  (.year2024Max, "iphone-2024-max"),
  (.year2025Air, "iphone-2025-air")
]

/// Every iPad screen, in alphabetical order of the family that ships it, paired with the stem its
/// reference files are named after.
private let tabletScreens: [(generation: DeviceProfile.TabletGeneration, name: String)] = [
  (.year2010, "ipad-2010"),
  (.year2015, "ipad-2015"),
  (.year2017, "ipad-2017"),
  (.year2018, "ipad-2018"),
  (.year2018Large, "ipad-2018-large"),
  (.year2019, "ipad-2019"),
  (.year2020, "ipad-2020"),
  (.year2021, "ipad-2021"),
  (.year2024, "ipad-2024"),
  (.year2024Large, "ipad-2024-large")
]

/// Window widths straddling `DeviceProfile.regularWidth`, the point a window turns horizontally
/// regular. Every one of them fits on the narrowest iPad in landscape.
private let windowWidths: [CGFloat] = [320, 375, 639, 640, 834]

/// Every content size category a user can choose, from smallest to largest, paired with the stem its
/// reference files are named after.
private let contentSizes: [(category: UIContentSizeCategory, name: String)] = [
  (.extraSmall, "extra-small"),
  (.small, "small"),
  (.medium, "medium"),
  (.large, "large"),
  (.extraLarge, "extra-large"),
  (.extraExtraLarge, "extra-extra-large"),
  (.extraExtraExtraLarge, "extra-extra-extra-large"),
  (.accessibilityMedium, "accessibility-medium"),
  (.accessibilityLarge, "accessibility-large"),
  (.accessibilityExtraLarge, "accessibility-extra-large"),
  (.accessibilityExtraExtraLarge, "accessibility-extra-extra-large"),
  (.accessibilityExtraExtraExtraLarge, "accessibility-extra-extra-extra-large")
]

#endif

// MARK: - The view under test

/// A view controller whose content fills its safe area, with an arrow pointing at each edge of it.
///
/// The content is drawn in ``UIColor/content`` and the insets around it in ``UIColor/inset``, so a
/// rendering shows how much room a screen reserves and on which sides. A caption in the middle names
/// the screen being rendered.
private final class SafeAreaViewController: UIViewController {
  private let captionLabel = UILabel()
  private let contentView = UIView()

  /// - Parameter caption: Text naming the screen the view is laid out on, drawn in the middle of the
  ///   safe area.
  init(caption: String) {
    super.init(nibName: nil, bundle: nil)
    self.captionLabel.text = caption
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) is unavailable")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.navigationItem.leftBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .add,
      target: nil,
      action: nil
    )

    self.view.backgroundColor = .inset
    self.contentView.backgroundColor = .content
    // Nothing may spill into the insets, or a large content size would paint over the very thing
    // the rendering is meant to show.
    self.contentView.clipsToBounds = true
    self.contentView.translatesAutoresizingMaskIntoConstraints = false
    self.view.addSubview(self.contentView)

    let safeArea = self.view.safeAreaLayoutGuide
    NSLayoutConstraint.activate([
      self.contentView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
      self.contentView.leftAnchor.constraint(equalTo: safeArea.leftAnchor),
      self.contentView.rightAnchor.constraint(equalTo: safeArea.rightAnchor),
      self.contentView.topAnchor.constraint(equalTo: safeArea.topAnchor)
    ])

    for edge in ArrowView.Edge.allCases {
      let arrow = ArrowView(pointing: edge)
      arrow.translatesAutoresizingMaskIntoConstraints = false
      self.contentView.addSubview(arrow)
      NSLayoutConstraint.activate(self.constraints(pinning: arrow))
    }

    self.captionLabel.lineBreakMode = .byTruncatingTail
    self.captionLabel.numberOfLines = 0
    self.captionLabel.textAlignment = .center
    self.captionLabel.textColor = .ink
    self.captionLabel.translatesAutoresizingMaskIntoConstraints = false
    self.contentView.addSubview(self.captionLabel)

    // The caption gives way rather than grow past the arrows, so that a content size large enough to
    // outrun the screen truncates instead of overflowing.
    self.captionLabel.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

    let margin = ArrowView.side + 8
    NSLayoutConstraint.activate([
      self.captionLabel.bottomAnchor.constraint(
        lessThanOrEqualTo: self.contentView.bottomAnchor,
        constant: -margin
      ),
      self.captionLabel.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
      self.captionLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: margin),
      self.captionLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -margin),
      self.captionLabel.topAnchor.constraint(
        greaterThanOrEqualTo: self.contentView.topAnchor,
        constant: margin
      )
    ])

    self.updateFont()
    self.registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) {
      (self: Self, _: UITraitCollection) in
      self.updateFont()
    }
  }

  /// Puts an arrow against the edge of the safe area it points at, centred on the other axis.
  private func constraints(pinning arrow: ArrowView) -> [NSLayoutConstraint] {
    switch arrow.edge {
    case .bottom:
      [
        arrow.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
        arrow.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor)
      ]
    case .left:
      [
        arrow.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
        arrow.leftAnchor.constraint(equalTo: self.contentView.leftAnchor)
      ]
    case .right:
      [
        arrow.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
        arrow.rightAnchor.constraint(equalTo: self.contentView.rightAnchor)
      ]
    case .top:
      [
        arrow.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor),
        arrow.topAnchor.constraint(equalTo: self.contentView.topAnchor)
      ]
    }
  }

  private func updateFont() {
    self.captionLabel.font = .preferredFont(
      forTextStyle: .body,
      compatibleWith: self.traitCollection
    )
  }
}

/// An arrow pointing at one edge of the view it is pinned to.
private final class ArrowView: UIView {
  /// The edge an arrow points at, named after the `UIEdgeInsets` field it marks.
  enum Edge: CaseIterable {
    case bottom
    case left
    case right
    case top

    /// The angle to turn an upwards arrow by so that it points at this edge.
    var rotation: CGFloat {
      switch self {
      case .bottom: .pi
      case .left: -.pi / 2
      case .right: .pi / 2
      case .top: 0
      }
    }
  }

  /// The width and the height of an arrow, in points.
  static let side: CGFloat = 32

  let edge: Edge

  init(pointing edge: Edge) {
    self.edge = edge
    super.init(frame: .zero)
    self.backgroundColor = .clear
    self.isOpaque = false
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) is unavailable")
  }

  override var intrinsicContentSize: CGSize {
    CGSize(width: Self.side, height: Self.side)
  }

  override func draw(_ rect: CGRect) {
    guard let context = UIGraphicsGetCurrentContext() else { return }

    // Turn the canvas rather than the path, so the arrow is only ever described pointing upwards.
    context.translateBy(x: self.bounds.midX, y: self.bounds.midY)
    context.rotate(by: self.edge.rotation)
    context.translateBy(x: -self.bounds.midX, y: -self.bounds.midY)

    let head = self.bounds.height / 2
    let shaft = self.bounds.width * 0.15
    let arrow = UIBezierPath()
    arrow.move(to: CGPoint(x: self.bounds.midX, y: self.bounds.minY))
    arrow.addLine(to: CGPoint(x: self.bounds.maxX, y: head))
    arrow.addLine(to: CGPoint(x: self.bounds.midX + shaft, y: head))
    arrow.addLine(to: CGPoint(x: self.bounds.midX + shaft, y: self.bounds.maxY))
    arrow.addLine(to: CGPoint(x: self.bounds.midX - shaft, y: self.bounds.maxY))
    arrow.addLine(to: CGPoint(x: self.bounds.midX - shaft, y: head))
    arrow.addLine(to: CGPoint(x: self.bounds.minX, y: head))
    arrow.close()

    UIColor.ink.setFill()
    arrow.fill()
  }
}

/// Fixed colours, so that a rendering does not depend on the interface style the host is in.
extension UIColor {
  /// The area a screen leaves for content, which the safe area covers.
  fileprivate static let content = UIColor(red: 1, green: 1, blue: 1, alpha: 1)

  /// The insets a screen reserves, in a hue that reads clearly against ``content``.
  fileprivate static let inset = UIColor(red: 0.96, green: 0.72, blue: 0.26, alpha: 1)

  /// The arrows and the caption drawn on ``content``.
  fileprivate static let ink = UIColor(red: 0.15, green: 0.16, blue: 0.2, alpha: 1)
}
#endif
