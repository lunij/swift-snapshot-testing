import Foundation
import XCTest

@testable import SnapshotTesting

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(SceneKit)
import SceneKit
#endif
#if canImport(SpriteKit)
import SpriteKit
import SwiftUI
#endif
#if canImport(WebKit)
@preconcurrency import WebKit
#endif
#if canImport(UIKit)
import UIKit.UIView
#endif

final class SnapshotTestingTests: BaseTestCase {
  private let fixturesURL = URL(fileURLWithPath: #filePath, isDirectory: false)
    .deletingLastPathComponent()
    .appendingPathComponent("__Fixtures__", isDirectory: true)

  func testAutolayout() async {
    #if os(iOS)
    let vc = UIViewController()
    vc.view.translatesAutoresizingMaskIntoConstraints = false
    let subview = UIView()
    subview.translatesAutoresizingMaskIntoConstraints = false
    vc.view.addSubview(subview)
    NSLayoutConstraint.activate([
      subview.topAnchor.constraint(equalTo: vc.view.topAnchor),
      subview.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor),
      subview.leftAnchor.constraint(equalTo: vc.view.leftAnchor),
      subview.rightAnchor.constraint(equalTo: vc.view.rightAnchor)
    ])
    await assertSnapshot(of: vc, as: .image)
    #endif
  }

  func testMixedViews() async {
    //    #if os(iOS) || os(macOS)
    //    // NB: CircleCI crashes while trying to instantiate SKView.
    //    if !CI {
    //      let webView = WKWebView(frame: .init(x: 0, y: 0, width: 50, height: 50))
    //      webView.loadHTMLString("🌎", baseURL: nil)
    //
    //      let skView = SKView(frame: .init(x: 50, y: 0, width: 50, height: 50))
    //      let scene = SKScene(size: .init(width: 50, height: 50))
    //      let node = SKShapeNode(circleOfRadius: 15)
    //      node.fillColor = .red
    //      node.position = .init(x: 25, y: 25)
    //      scene.addChild(node)
    //      skView.presentScene(scene)
    //
    //      let view = View(frame: .init(x: 0, y: 0, width: 100, height: 50))
    //      view.addSubview(webView)
    //      view.addSubview(skView)
    //
    //      await assertSnapshot(of: view, as: .image, named: platform)
    //    }
    //    #endif
  }

  #if os(macOS)
  func testNSView() async {
    let button = NSButton()
    button.bezelStyle = .rounded
    button.title = "Push Me"
    button.sizeToFit()
    await assertSnapshot(of: button, as: .image, named: "\(platform)\(osVersion.majorVersion)")
    await assertSnapshot(of: button, as: .recursiveDescription, named: "\(platform)\(osVersion.majorVersion)")
  }

  func testNSViewWithLayer() async {
    let view = NSView()
    view.frame = CGRect(x: 0, y: 0, width: 10, height: 10)
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.green.cgColor
    view.layer?.cornerRadius = 5
    await assertSnapshot(of: view, as: .image, named: "\(platform)\(osVersion.majorVersion)")
    await assertSnapshot(of: view, as: .recursiveDescription, named: platform)
  }
  #endif

  #if os(iOS) || os(macOS) || os(tvOS)
  func testPrecision() async {
    let view = XView(frame: .init(x: 0, y: 0, width: 100, height: 100))  // 10000 pixels
    view.backgroundColor = .blue
    await assertSnapshot(of: view, as: .image(precision: 1, perceptualPrecision: 1), named: "\(platform)-original")

    let subview = XView(frame: .init(x: 0, y: 0, width: 10, height: 10))  // 100 pixels
    subview.backgroundColor = .red
    view.addSubview(subview)
    await assertSnapshot(of: view, as: .image(precision: 1, perceptualPrecision: 1), named: "\(platform)-modified")

    var message = await verifySnapshot(of: view, as: .image(precision: 0.999, perceptualPrecision: 1), named: "\(platform)-original", record: .never)
    let firstLine = message?.split(whereSeparator: \.isNewline).first
    XCTAssertEqual(firstLine, "[\(platform)-original] Image does not match reference (pixel precision 0.995 is less than required 0.999).")

    // 10000-100=9900 => 99% precision
    message = await verifySnapshot(of: view, as: .image(precision: 0.99, perceptualPrecision: 1), named: "\(platform)-original", record: .never)
    XCTAssertNil(message)
  }

  func testPerceptualPrecision() async {
    let view = XView(frame: .init(x: 0, y: 0, width: 100, height: 100))
    view.backgroundColor = .black
    await assertSnapshot(of: view, as: .image(precision: 1, perceptualPrecision: 1), named: platform + "-original")

    view.backgroundColor = .init(white: 0.0019, alpha: 1)
    await assertSnapshot(of: view, as: .image(precision: 1, perceptualPrecision: 1), named: platform + "-modified")

    await assertSnapshot(of: view, as: .image(precision: 1, perceptualPrecision: 0.98), named: platform + "-original", record: .never)
  }

  func testImagePrecision() async throws {
    let imageURL = fixturesURL.appendingPathComponent("testImagePrecision.reference.png")
    let image = try XCTUnwrap(XImage(contentsOf: imageURL))

    await assertSnapshot(of: image, as: .image(precision: 0.995), named: "exact")
    await assertSnapshot(of: image, as: .image(perceptualPrecision: 0.98), named: "perceptual")
  }
  #endif

  func testSCNView() async {
    // #if os(iOS) || os(macOS) || os(tvOS)
    // // NB: CircleCI crashes while trying to instantiate SCNView.
    // if !CI {
    //   let scene = SCNScene()
    //
    //   let sphereGeometry = SCNSphere(radius: 3)
    //   sphereGeometry.segmentCount = 200
    //   let sphereNode = SCNNode(geometry: sphereGeometry)
    //   sphereNode.position = SCNVector3Zero
    //   scene.rootNode.addChildNode(sphereNode)
    //
    //   sphereGeometry.firstMaterial?.diffuse.contents = URL(fileURLWithPath: String(#file), isDirectory: false)
    //     .deletingLastPathComponent()
    //     .appendingPathComponent("__Fixtures__/earth.png")
    //
    //   let cameraNode = SCNNode()
    //   cameraNode.camera = SCNCamera()
    //   cameraNode.position = SCNVector3Make(0, 0, 8)
    //   scene.rootNode.addChildNode(cameraNode)
    //
    //   let omniLight = SCNLight()
    //   omniLight.type = .omni
    //   let omniLightNode = SCNNode()
    //   omniLightNode.light = omniLight
    //   omniLightNode.position = SCNVector3Make(10, 10, 10)
    //   scene.rootNode.addChildNode(omniLightNode)
    //
    //   await assertSnapshot(
    //     of: scene,
    //     as: .image(size: .init(width: 500, height: 500)),
    //     named: platform
    //   )
    // }
    // #endif
  }

  func testSKView() async {
    // #if os(iOS) || os(macOS) || os(tvOS)
    // // NB: CircleCI crashes while trying to instantiate SKView.
    // if !CI {
    //   let scene = SKScene(size: .init(width: 50, height: 50))
    //   let node = SKShapeNode(circleOfRadius: 15)
    //   node.fillColor = .red
    //   node.position = .init(x: 25, y: 25)
    //   scene.addChild(node)
    //
    //   await assertSnapshot(
    //     of: scene,
    //     as: .image(size: .init(width: 50, height: 50)),
    //     named: platform
    //   )
    // }
    // #endif
  }

  func testTableViewController() async {
    #if os(iOS)
    class TableViewController: UITableViewController {
      override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
      }
      override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
      }
      override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
      )
        -> UITableViewCell
      {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = "\(indexPath.row)"
        return cell
      }
    }
    let tableViewController = TableViewController()
    await assertSnapshot(of: tableViewController, as: .image(on: .iPhoneSe))
    #endif
  }

  func testAssertMultipleSnapshot() async {
    #if os(iOS)
    class TableViewController: UITableViewController {
      override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
      }
      override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
      }
      override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
      )
        -> UITableViewCell
      {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = "\(indexPath.row)"
        return cell
      }
    }
    let tableViewController = TableViewController()
    await assertSnapshots(
      of: tableViewController,
      as: ["iPhoneSE-image": .image(on: .iPhoneSe), "iPad-image": .image(on: .iPadMini)]
    )
    await assertSnapshots(
      of: tableViewController,
      as: [.image(on: .iPhoneX), .image(on: .iPhoneXsMax)]
    )
    #endif
  }

  func testTraits() async {
    #if os(iOS) || os(tvOS)
    if #available(iOS 11.0, tvOS 11.0, *) {
      class MyViewController: UIViewController {
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

      let viewController = MyViewController()

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
      class MyViewController: UIViewController {
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

      let myViewController = MyViewController()
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

  func testCollectionViewsWithMultipleScreenSizes() async {
    #if os(iOS)

    final class CollectionViewController: UIViewController, UICollectionViewDataSource,
      UICollectionViewDelegateFlowLayout
    {

      let flowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 20
        return layout
      }()

      lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)

      override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        view.addSubview(collectionView)

        collectionView.backgroundColor = .white
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
          collectionView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
          collectionView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
          collectionView.trailingAnchor.constraint(
            equalTo: view.layoutMarginsGuide.trailingAnchor
          ),
          collectionView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor)
        ])

        collectionView.reloadData()

        registerForTraitChanges(
          [UITraitHorizontalSizeClass.self, UITraitVerticalSizeClass.self]
        ) { (self: Self, _: UITraitCollection) in
          self.collectionView.collectionViewLayout.invalidateLayout()
        }
      }

      override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
      }

      func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
      )
        -> UICollectionViewCell
      {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        cell.contentView.backgroundColor = .orange
        return cell
      }

      func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
      )
        -> Int
      {
        return 20
      }

      func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
      ) -> CGSize {
        return CGSize(
          width: min(collectionView.frame.width - 50, 300),
          height: collectionView.frame.height
        )
      }

    }

    let viewController = CollectionViewController()

    await assertSnapshots(
      of: viewController,
      as: [
        "ipad": .image(on: .iPadPro12_9),
        "iphoneSe": .image(on: .iPhoneSe),
        "iphone8": .image(on: .iPhone8),
        "iphoneMax": .image(on: .iPhoneXsMax)
      ]
    )
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

  func testUIView() async {
    #if os(iOS)
    let view = UIButton(type: .contactAdd)
    await assertSnapshot(of: view, as: .image)
    await assertSnapshot(of: view, as: .recursiveDescription)
    #endif
  }

  func testUIViewControllerLifeCycle() async {
    #if os(iOS)
    class ViewController: UIViewController {
      let viewDidLoadExpectation = XCTestExpectation(description: "viewDidLoad")

      let viewWillAppearExpectation = XCTestExpectation(description: "viewWillAppear")
      let viewDidAppearExpectation = XCTestExpectation(description: "viewDidAppear")

      let viewWillDisappearExpectation = XCTestExpectation(description: "viewWillDisappear")
      let viewDidDisappearExpectation = XCTestExpectation(description: "viewDidDisappear")

      override func viewDidLoad() {
        super.viewDidLoad()
        viewDidLoadExpectation.fulfill()
      }
      override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearExpectation.fulfill()
      }
      override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewDidAppearExpectation.fulfill()
      }
      override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewWillDisappearExpectation.fulfill()
      }
      override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewDidDisappearExpectation.fulfill()
      }
    }

    let viewController = ViewController()
    viewController.viewWillAppearExpectation.expectedFulfillmentCount = 2
    viewController.viewDidAppearExpectation.expectedFulfillmentCount = 2
    viewController.viewWillDisappearExpectation.expectedFulfillmentCount = 1
    viewController.viewDidDisappearExpectation.expectedFulfillmentCount = 1

    await assertSnapshot(of: viewController, as: .image)

    await fulfillment(
      of: [
        viewController.viewDidLoadExpectation,
        viewController.viewWillAppearExpectation,
        viewController.viewDidAppearExpectation,
        viewController.viewWillDisappearExpectation,
        viewController.viewDidDisappearExpectation
      ],
      enforceOrder: true
    )
    #endif
  }

  func testViewControllerHierarchy() async {
    #if os(iOS)
    let page = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
    page.setViewControllers([UIViewController()], direction: .forward, animated: false)
    let tab = UITabBarController()
    tab.viewControllers = [
      UINavigationController(rootViewController: page),
      UINavigationController(rootViewController: UIViewController()),
      UINavigationController(rootViewController: UIViewController()),
      UINavigationController(rootViewController: UIViewController()),
      UINavigationController(rootViewController: UIViewController())
    ]
    await assertSnapshot(of: tab, as: .hierarchy)
    #endif
  }

  func testURLRequest() async {
    var get = URLRequest(url: URL(string: "https://www.pointfree.co/")!)
    get.addValue("pf_session={}", forHTTPHeaderField: "Cookie")
    get.addValue("text/html", forHTTPHeaderField: "Accept")
    get.addValue("application/json", forHTTPHeaderField: "Content-Type")
    await assertSnapshot(of: get, as: .raw, named: "get")
    await assertSnapshot(of: get, as: .curl, named: "get-curl")

    var getWithQuery = URLRequest(
      url: URL(string: "https://www.pointfree.co?key_2=value_2&key_1=value_1&key_3=value_3")!
    )
    getWithQuery.addValue("pf_session={}", forHTTPHeaderField: "Cookie")
    getWithQuery.addValue("text/html", forHTTPHeaderField: "Accept")
    getWithQuery.addValue("application/json", forHTTPHeaderField: "Content-Type")
    await assertSnapshot(of: getWithQuery, as: .raw, named: "get-with-query")
    await assertSnapshot(of: getWithQuery, as: .curl, named: "get-with-query-curl")

    var post = URLRequest(url: URL(string: "https://www.pointfree.co/subscribe")!)
    post.httpMethod = "POST"
    post.addValue("pf_session={\"user_id\":\"0\"}", forHTTPHeaderField: "Cookie")
    post.addValue("text/html", forHTTPHeaderField: "Accept")
    post.httpBody = Data("pricing[billing]=monthly&pricing[lane]=individual".utf8)
    await assertSnapshot(of: post, as: .raw, named: "post")
    await assertSnapshot(of: post, as: .curl, named: "post-curl")

    var postWithJSON = URLRequest(
      url: URL(string: "http://dummy.restapiexample.com/api/v1/create")!
    )
    postWithJSON.httpMethod = "POST"
    postWithJSON.addValue("application/json", forHTTPHeaderField: "Content-Type")
    postWithJSON.addValue("application/json", forHTTPHeaderField: "Accept")
    postWithJSON.httpBody = Data(
      "{\"name\":\"tammy134235345235\", \"salary\":0, \"age\":\"tammy133\"}".utf8
    )
    await assertSnapshot(of: postWithJSON, as: .raw, named: "post-with-json")
    await assertSnapshot(of: postWithJSON, as: .curl, named: "post-with-json-curl")

    var head = URLRequest(url: URL(string: "https://www.pointfree.co/")!)
    head.httpMethod = "HEAD"
    head.addValue("pf_session={}", forHTTPHeaderField: "Cookie")
    await assertSnapshot(of: head, as: .raw, named: "head")
    await assertSnapshot(of: head, as: .curl, named: "head-curl")

    post = URLRequest(url: URL(string: "https://www.pointfree.co/subscribe")!)
    post.httpMethod = "POST"
    post.addValue("pf_session={\"user_id\":\"0\"}", forHTTPHeaderField: "Cookie")
    post.addValue("application/json", forHTTPHeaderField: "Accept")
    post.httpBody = Data(
      """
      {"pricing": {"lane": "individual","billing": "monthly"}}
      """.utf8
    )
  }

  #if canImport(SwiftUI)
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
  #endif
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

#if os(iOS) || os(macOS) || os(tvOS)
extension XImage {
  convenience init?(contentsOf url: URL) {
    #if os(iOS) || os(tvOS)
    self.init(contentsOfFile: url.path)
    #elseif os(macOS)
    self.init(byReferencing: url)
    #endif
  }
}
#endif

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
