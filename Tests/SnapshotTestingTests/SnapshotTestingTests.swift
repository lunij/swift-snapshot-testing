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
  import WebKit
#endif
#if canImport(UIKit)
  import UIKit.UIView
#endif

final class SnapshotTestingTests: XCTestCase {
  private let fixturesURL = URL(fileURLWithPath: #file, isDirectory: false)
    .deletingLastPathComponent()
    .appendingPathComponent("__Fixtures__", isDirectory: true)

  override func setUp() {
    super.setUp()
    diffTool = "ksdiff"
    // isRecording = true
  }

  override func tearDown() {
    isRecording = false
    super.tearDown()
  }

  func testAny() {
    struct User { let id: Int, name: String, bio: String }
    let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")
    assertSnapshot(of: user, as: .dump)
  }

  @available(macOS 10.13, tvOS 11.0, *)
  func testAnyAsJson() throws {
    struct User: Encodable { let id: Int, name: String, bio: String }
    let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")

    let data = try JSONEncoder().encode(user)
    let any = try JSONSerialization.jsonObject(with: data, options: [])

    assertSnapshot(of: any, as: .json)
  }

  func testAnySnapshotStringConvertible() {
    assertSnapshot(of: "a" as Character, as: .dump, named: "character")
    assertSnapshot(of: Data("Hello, world!".utf8), as: .dump, named: "data")
    assertSnapshot(of: Date(timeIntervalSinceReferenceDate: 0), as: .dump, named: "date")
    assertSnapshot(of: NSObject(), as: .dump, named: "nsobject")
    assertSnapshot(of: "Hello, world!", as: .dump, named: "string")
    assertSnapshot(of: "Hello, world!".dropLast(8), as: .dump, named: "substring")
    assertSnapshot(of: URL(string: "https://www.pointfree.co")!, as: .dump, named: "url")
  }

  func testAutolayout() {
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
        subview.rightAnchor.constraint(equalTo: vc.view.rightAnchor),
      ])
      assertSnapshot(of: vc, as: .image)
    #endif
  }

  func testDeterministicDictionaryAndSetSnapshots() {
    struct Person: Hashable { let name: String }
    struct DictionarySetContainer { let dict: [String: Int], set: Set<Person> }
    let set = DictionarySetContainer(
      dict: ["c": 3, "a": 1, "b": 2],
      set: [.init(name: "Brandon"), .init(name: "Stephen")]
    )
    assertSnapshot(of: set, as: .dump)
  }

  func testCaseIterable() {
    enum Direction: String, CaseIterable {
      case up, down, left, right
      var rotatedLeft: Direction {
        switch self {
        case .up: return .left
        case .down: return .right
        case .left: return .down
        case .right: return .up
        }
      }
    }

    assertSnapshot(
      of: { $0.rotatedLeft },
      as: Snapshotting<Direction, String>.func(into: .description)
    )
  }

#if os(iOS) || os(macOS) || os(tvOS)
  func testCGPath() {
    let path = CGPath.heart
    assertSnapshot(of: path, as: .image, named: platform)
    assertSnapshot(of: path, as: .elementsDescription, named: platform)
  }
#endif

#if os(macOS)
  func testNSBezierPath() {
    let path = NSBezierPath.heart
    assertSnapshot(of: path, as: .image)
    assertSnapshot(of: path, as: .elementsDescription)
  }
#endif

  func testData() {
    let data = Data([0xDE, 0xAD, 0xBE, 0xEF])

    assertSnapshot(of: data, as: .data)
  }

  func testEncodable() {
    struct User: Encodable { let id: Int, name: String, bio: String }
    let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")

    if #available(iOS 11.0, macOS 10.13, tvOS 11.0, *) {
      assertSnapshot(of: user, as: .json)
    }
    assertSnapshot(of: user, as: .plist)
  }

  func testMixedViews() {
    //    #if os(iOS) || os(macOS)
    //    // NB: CircleCI crashes while trying to instantiate SKView.
    //    if !ProcessInfo.processInfo.environment.keys.contains("GITHUB_WORKFLOW") {
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
    //      assertSnapshot(of: view, as: .image, named: platform)
    //    }
    //    #endif
  }

  func testMultipleSnapshots() {
    assertSnapshot(of: [1], as: .dump)
    assertSnapshot(of: [1, 2], as: .dump)
  }

  func testNamedAssertion() {
    struct User { let id: Int, name: String, bio: String }
    let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")
    assertSnapshot(of: user, as: .dump, named: "named")
  }

  #if os(macOS)
    func testNSView() {
      let button = NSButton()
      button.bezelStyle = .rounded
      button.title = "Push Me"
      button.sizeToFit()
      assertSnapshot(of: button, as: .image, named: "\(platform)\(osVersion.majorVersion)")
      assertSnapshot(of: button, as: .recursiveDescription, named: "\(platform)\(osVersion.majorVersion)")
    }

    func testNSViewWithLayer() {
      let view = NSView()
      view.frame = CGRect(x: 0, y: 0, width: 10, height: 10)
      view.wantsLayer = true
      view.layer?.backgroundColor = NSColor.green.cgColor
      view.layer?.cornerRadius = 5
      assertSnapshot(of: view, as: .image, named: "\(platform)\(osVersion.majorVersion)")
      assertSnapshot(of: view, as: .recursiveDescription, named: "\(platform)\(osVersion.majorVersion)")
    }
  #endif

  #if os(iOS) || os(macOS) || os(tvOS)
    func testPrecision() {
      let view = XView(frame: .init(x: 0, y: 0, width: 100, height: 100)) // 10000 pixels
      view.backgroundColor = .blue
      assertSnapshot(of: view, as: .image(precision: 1, perceptualPrecision: 1), named: platform + "-original")

      let subview = XView(frame: .init(x: 0, y: 0, width: 10, height: 10)) // 100 pixels
      subview.backgroundColor = .red
      view.addSubview(subview)
      assertSnapshot(of: view, as: .image(precision: 1, perceptualPrecision: 1), named: platform + "-modified")

      var message = verifySnapshot(of: view, as: .image(precision: 0.999, perceptualPrecision: 1), named: platform + "-original")
      let firstLine = message?.split(whereSeparator: \.isNewline).first
      XCTAssertEqual(firstLine, "[\(platform)-original] Actual image precision 0.995 is less than expected 0.999")

      // 10000-100=9900 => 99% precision
      message = verifySnapshot(of: view, as: .image(precision: 0.99, perceptualPrecision: 1), named: platform + "-original")
      XCTAssertNil(message)
    }

    func testPerceptualPrecision() {
      let view = XView(frame: .init(x: 0, y: 0, width: 100, height: 100))
      view.backgroundColor = .black
      assertSnapshot(of: view, as: .image(precision: 1, perceptualPrecision: 1), named: platform + "-original")

      view.backgroundColor = .init(white: 0.0019, alpha: 1)
      assertSnapshot(of: view, as: .image(precision: 1, perceptualPrecision: 1), named: platform + "-modified")

      assertSnapshot(of: view, as: .image(precision: 1, perceptualPrecision: 0.98), named: platform + "-original")
    }

    func testImagePrecision() throws {
      let imageURL = fixturesURL.appendingPathComponent("testImagePrecision.reference.png")
      let image = try XCTUnwrap(XImage(contentsOf: imageURL))

      assertSnapshot(of: image, as: .image(precision: 0.995), named: "exact")
      assertSnapshot(of: image, as: .image(perceptualPrecision: 0.98), named: "perceptual")
    }
  #endif

  func testSCNView() {
    // #if os(iOS) || os(macOS) || os(tvOS)
    // // NB: CircleCI crashes while trying to instantiate SCNView.
    // if !ProcessInfo.processInfo.environment.keys.contains("GITHUB_WORKFLOW") {
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
    //   assertSnapshot(
    //     of: scene,
    //     as: .image(size: .init(width: 500, height: 500)),
    //     named: platform
    //   )
    // }
    // #endif
  }

  func testSKView() {
    // #if os(iOS) || os(macOS) || os(tvOS)
    // // NB: CircleCI crashes while trying to instantiate SKView.
    // if !ProcessInfo.processInfo.environment.keys.contains("GITHUB_WORKFLOW") {
    //   let scene = SKScene(size: .init(width: 50, height: 50))
    //   let node = SKShapeNode(circleOfRadius: 15)
    //   node.fillColor = .red
    //   node.position = .init(x: 25, y: 25)
    //   scene.addChild(node)
    //
    //   assertSnapshot(
    //     of: scene,
    //     as: .image(size: .init(width: 50, height: 50)),
    //     named: platform
    //   )
    // }
    // #endif
  }

  func testTableViewController() {
    #if os(iOS)
      class TableViewController: UITableViewController {
        override func viewDidLoad() {
          super.viewDidLoad()
          self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        }
        override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
        {
          return 10
        }
        override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
          -> UITableViewCell
        {
          let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
          cell.textLabel?.text = "\(indexPath.row)"
          return cell
        }
      }
      let tableViewController = TableViewController()
      assertSnapshot(of: tableViewController, as: .image(on: .iPhoneSe))
    #endif
  }

  func testAssertMultipleSnapshot() {
    #if os(iOS)
      class TableViewController: UITableViewController {
        override func viewDidLoad() {
          super.viewDidLoad()
          self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        }
        override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
        {
          return 10
        }
        override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
          -> UITableViewCell
        {
          let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
          cell.textLabel?.text = "\(indexPath.row)"
          return cell
        }
      }
      let tableViewController = TableViewController()
      assertSnapshots(
        of: tableViewController,
        as: ["iPhoneSE-image": .image(on: .iPhoneSe), "iPad-image": .image(on: .iPadMini)])
      assertSnapshots(
        of: tableViewController, as: [.image(on: .iPhoneX), .image(on: .iPhoneXsMax)])
    #endif
  }

  func testTraits() {
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
              barButtonSystemItem: .add, target: nil, action: nil)

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
                equalTo: self.view.safeAreaLayoutGuide.centerXAnchor),
              self.leadingLabel.leadingAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
              self.leadingLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: self.view.safeAreaLayoutGuide.centerXAnchor),
              //            self.leadingLabel.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor),
              self.leadingLabel.centerYAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.centerYAnchor),
              self.trailingLabel.leadingAnchor.constraint(
                greaterThanOrEqualTo: self.view.safeAreaLayoutGuide.centerXAnchor),
              self.trailingLabel.trailingAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
              self.trailingLabel.centerYAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.centerYAnchor),
              self.bottomLabel.bottomAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
              self.bottomLabel.centerXAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.centerXAnchor),
            ])
          }

          override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
            self.topLabel.font = .preferredFont(
              forTextStyle: .headline, compatibleWith: self.traitCollection)
            self.leadingLabel.font = .preferredFont(
              forTextStyle: .body, compatibleWith: self.traitCollection)
            self.trailingLabel.font = .preferredFont(
              forTextStyle: .body, compatibleWith: self.traitCollection)
            self.bottomLabel.font = .preferredFont(
              forTextStyle: .subheadline, compatibleWith: self.traitCollection)
            self.view.setNeedsUpdateConstraints()
            self.view.updateConstraintsIfNeeded()
          }
        }

        let viewController = MyViewController()

        #if os(iOS)
          assertSnapshot(of: viewController, as: .image(on: .iPhoneSe), named: "iphone-se")
          assertSnapshot(of: viewController, as: .image(on: .iPhone8), named: "iphone-8")
          assertSnapshot(of: viewController, as: .image(on: .iPhone8Plus), named: "iphone-8-plus")
          assertSnapshot(of: viewController, as: .image(on: .iPhoneX), named: "iphone-x")
          assertSnapshot(of: viewController, as: .image(on: .iPhoneXr), named: "iphone-xr")
          assertSnapshot(of: viewController, as: .image(on: .iPhoneXsMax), named: "iphone-xs-max")
          assertSnapshot(of: viewController, as: .image(on: .iPadMini), named: "ipad-mini")
          assertSnapshot(of: viewController, as: .image(on: .iPad9_7), named: "ipad-9-7")
          assertSnapshot(of: viewController, as: .image(on: .iPad10_2), named: "ipad-10-2")
          assertSnapshot(of: viewController, as: .image(on: .iPadPro10_5), named: "ipad-pro-10-5")
          assertSnapshot(of: viewController, as: .image(on: .iPadPro11), named: "ipad-pro-11")
          assertSnapshot(of: viewController, as: .image(on: .iPadPro12_9), named: "ipad-pro-12-9")

          assertSnapshot(
            of: viewController, as: .recursiveDescription(on: .iPhoneSe), named: "iphone-se")
          assertSnapshot(
            of: viewController, as: .recursiveDescription(on: .iPhone8), named: "iphone-8")
          assertSnapshot(
            of: viewController, as: .recursiveDescription(on: .iPhone8Plus), named: "iphone-8-plus")
          assertSnapshot(
            of: viewController, as: .recursiveDescription(on: .iPhoneX), named: "iphone-x")
          assertSnapshot(
            of: viewController, as: .recursiveDescription(on: .iPhoneXr), named: "iphone-xr")
          assertSnapshot(
            of: viewController, as: .recursiveDescription(on: .iPhoneXsMax), named: "iphone-xs-max")
          assertSnapshot(
            of: viewController, as: .recursiveDescription(on: .iPadMini), named: "ipad-mini")
          assertSnapshot(
            of: viewController, as: .recursiveDescription(on: .iPad9_7), named: "ipad-9-7")
          assertSnapshot(
            of: viewController, as: .recursiveDescription(on: .iPad10_2), named: "ipad-10-2")
          assertSnapshot(
            of: viewController, as: .recursiveDescription(on: .iPadPro10_5), named: "ipad-pro-10-5")
          assertSnapshot(
            of: viewController, as: .recursiveDescription(on: .iPadPro11), named: "ipad-pro-11")
          assertSnapshot(
            of: viewController, as: .recursiveDescription(on: .iPadPro12_9), named: "ipad-pro-12-9")

          assertSnapshot(
            of: viewController, as: .image(on: .iPhoneSe(.portrait)), named: "iphone-se")
          assertSnapshot(of: viewController, as: .image(on: .iPhone8(.portrait)), named: "iphone-8")
          assertSnapshot(
            of: viewController, as: .image(on: .iPhone8Plus(.portrait)), named: "iphone-8-plus")
          assertSnapshot(of: viewController, as: .image(on: .iPhoneX(.portrait)), named: "iphone-x")
          assertSnapshot(
            of: viewController, as: .image(on: .iPhoneXr(.portrait)), named: "iphone-xr")
          assertSnapshot(
            of: viewController, as: .image(on: .iPhoneXsMax(.portrait)), named: "iphone-xs-max")
          assertSnapshot(
            of: viewController, as: .image(on: .iPadMini(.landscape)), named: "ipad-mini")
          assertSnapshot(
            of: viewController, as: .image(on: .iPad9_7(.landscape)), named: "ipad-9-7")
          assertSnapshot(
            of: viewController, as: .image(on: .iPad10_2(.landscape)), named: "ipad-10-2")
          assertSnapshot(
            of: viewController, as: .image(on: .iPadPro10_5(.landscape)), named: "ipad-pro-10-5")
          assertSnapshot(
            of: viewController, as: .image(on: .iPadPro11(.landscape)), named: "ipad-pro-11")
          assertSnapshot(
            of: viewController, as: .image(on: .iPadPro12_9(.landscape)), named: "ipad-pro-12-9")

          assertSnapshot(
            of: viewController, as: .image(on: .iPadMini(.landscape(splitView: .oneThird))),
            named: "ipad-mini-33-split-landscape")
          assertSnapshot(
            of: viewController, as: .image(on: .iPadMini(.landscape(splitView: .oneHalf))),
            named: "ipad-mini-50-split-landscape")
          assertSnapshot(
            of: viewController, as: .image(on: .iPadMini(.landscape(splitView: .twoThirds))),
            named: "ipad-mini-66-split-landscape")
          assertSnapshot(
            of: viewController, as: .image(on: .iPadMini(.portrait(splitView: .oneThird))),
            named: "ipad-mini-33-split-portrait")
          assertSnapshot(
            of: viewController, as: .image(on: .iPadMini(.portrait(splitView: .twoThirds))),
            named: "ipad-mini-66-split-portrait")

          assertSnapshot(
            of: viewController, as: .image(on: .iPad9_7(.landscape(splitView: .oneThird))),
            named: "ipad-9-7-33-split-landscape")
          assertSnapshot(
            of: viewController, as: .image(on: .iPad9_7(.landscape(splitView: .oneHalf))),
            named: "ipad-9-7-50-split-landscape")
          assertSnapshot(
            of: viewController, as: .image(on: .iPad9_7(.landscape(splitView: .twoThirds))),
            named: "ipad-9-7-66-split-landscape")
          assertSnapshot(
            of: viewController, as: .image(on: .iPad9_7(.portrait(splitView: .oneThird))),
            named: "ipad-9-7-33-split-portrait")
          assertSnapshot(
            of: viewController, as: .image(on: .iPad9_7(.portrait(splitView: .twoThirds))),
            named: "ipad-9-7-66-split-portrait")

          assertSnapshot(
            of: viewController, as: .image(on: .iPad10_2(.landscape(splitView: .oneThird))),
            named: "ipad-10-2-split-landscape")
          assertSnapshot(
            of: viewController, as: .image(on: .iPad10_2(.landscape(splitView: .oneHalf))),
            named: "ipad-10-2-50-split-landscape")
          assertSnapshot(
            of: viewController, as: .image(on: .iPad10_2(.landscape(splitView: .twoThirds))),
            named: "ipad-10-2-66-split-landscape")
          assertSnapshot(
            of: viewController, as: .image(on: .iPad10_2(.portrait(splitView: .oneThird))),
            named: "ipad-10-2-33-split-portrait")
          assertSnapshot(
            of: viewController, as: .image(on: .iPad10_2(.portrait(splitView: .twoThirds))),
            named: "ipad-10-2-66-split-portrait")

          assertSnapshot(
            of: viewController, as: .image(on: .iPadPro10_5(.landscape(splitView: .oneThird))),
            named: "ipad-pro-10inch-33-split-landscape")
          assertSnapshot(
            of: viewController, as: .image(on: .iPadPro10_5(.landscape(splitView: .oneHalf))),
            named: "ipad-pro-10inch-50-split-landscape")
          assertSnapshot(
            of: viewController, as: .image(on: .iPadPro10_5(.landscape(splitView: .twoThirds))),
            named: "ipad-pro-10inch-66-split-landscape")
          assertSnapshot(
            of: viewController, as: .image(on: .iPadPro10_5(.portrait(splitView: .oneThird))),
            named: "ipad-pro-10inch-33-split-portrait")
          assertSnapshot(
            of: viewController, as: .image(on: .iPadPro10_5(.portrait(splitView: .twoThirds))),
            named: "ipad-pro-10inch-66-split-portrait")

          assertSnapshot(
            of: viewController, as: .image(on: .iPadPro11(.landscape(splitView: .oneThird))),
            named: "ipad-pro-11inch-33-split-landscape")
          assertSnapshot(
            of: viewController, as: .image(on: .iPadPro11(.landscape(splitView: .oneHalf))),
            named: "ipad-pro-11inch-50-split-landscape")
          assertSnapshot(
            of: viewController, as: .image(on: .iPadPro11(.landscape(splitView: .twoThirds))),
            named: "ipad-pro-11inch-66-split-landscape")
          assertSnapshot(
            of: viewController, as: .image(on: .iPadPro11(.portrait(splitView: .oneThird))),
            named: "ipad-pro-11inch-33-split-portrait")
          assertSnapshot(
            of: viewController, as: .image(on: .iPadPro11(.portrait(splitView: .twoThirds))),
            named: "ipad-pro-11inch-66-split-portrait")

          assertSnapshot(
            of: viewController, as: .image(on: .iPadPro12_9(.landscape(splitView: .oneThird))),
            named: "ipad-pro-12inch-33-split-landscape")
          assertSnapshot(
            of: viewController, as: .image(on: .iPadPro12_9(.landscape(splitView: .oneHalf))),
            named: "ipad-pro-12inch-50-split-landscape")
          assertSnapshot(
            of: viewController, as: .image(on: .iPadPro12_9(.landscape(splitView: .twoThirds))),
            named: "ipad-pro-12inch-66-split-landscape")
          assertSnapshot(
            of: viewController, as: .image(on: .iPadPro12_9(.portrait(splitView: .oneThird))),
            named: "ipad-pro-12inch-33-split-portrait")
          assertSnapshot(
            of: viewController, as: .image(on: .iPadPro12_9(.portrait(splitView: .twoThirds))),
            named: "ipad-pro-12inch-66-split-portrait")

          assertSnapshot(
            of: viewController, as: .image(on: .iPhoneSe(.landscape)),
            named: "iphone-se-alternative")
          assertSnapshot(
            of: viewController, as: .image(on: .iPhone8(.landscape)), named: "iphone-8-alternative")
          assertSnapshot(
            of: viewController, as: .image(on: .iPhone8Plus(.landscape)),
            named: "iphone-8-plus-alternative")
          assertSnapshot(
            of: viewController, as: .image(on: .iPhoneX(.landscape)), named: "iphone-x-alternative")
          assertSnapshot(
            of: viewController, as: .image(on: .iPhoneXr(.landscape)),
            named: "iphone-xr-alternative")
          assertSnapshot(
            of: viewController, as: .image(on: .iPhoneXsMax(.landscape)),
            named: "iphone-xs-max-alternative")
          assertSnapshot(
            of: viewController, as: .image(on: .iPadMini(.portrait)), named: "ipad-mini-alternative"
          )
          assertSnapshot(
            of: viewController, as: .image(on: .iPad9_7(.portrait)), named: "ipad-9-7-alternative")
          assertSnapshot(
            of: viewController, as: .image(on: .iPad10_2(.portrait)), named: "ipad-10-2-alternative"
          )
          assertSnapshot(
            of: viewController, as: .image(on: .iPadPro10_5(.portrait)),
            named: "ipad-pro-10-5-alternative")
          assertSnapshot(
            of: viewController, as: .image(on: .iPadPro11(.portrait)),
            named: "ipad-pro-11-alternative")
          assertSnapshot(
            of: viewController, as: .image(on: .iPadPro12_9(.portrait)),
            named: "ipad-pro-12-9-alternative")

          allContentSizes.forEach { name, contentSize in
            assertSnapshot(
              of: viewController,
              as: .image(on: .iPhoneSe, traits: .init(preferredContentSizeCategory: contentSize)),
              named: "iphone-se-\(name)"
            )
          }
        #elseif os(tvOS)
          assertSnapshot(
            of: viewController, as: .image(on: .tv), named: "tv")
          assertSnapshot(
            of: viewController, as: .image(on: .tv4K), named: "tv4k")
        #endif
      }
    #endif
  }

  func testTraitsEmbeddedInTabNavigation() {
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
              barButtonSystemItem: .add, target: nil, action: nil)

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
                equalTo: self.view.safeAreaLayoutGuide.centerXAnchor),
              self.leadingLabel.leadingAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
              self.leadingLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: self.view.safeAreaLayoutGuide.centerXAnchor),
              //            self.leadingLabel.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor),
              self.leadingLabel.centerYAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.centerYAnchor),
              self.trailingLabel.leadingAnchor.constraint(
                greaterThanOrEqualTo: self.view.safeAreaLayoutGuide.centerXAnchor),
              self.trailingLabel.trailingAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
              self.trailingLabel.centerYAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.centerYAnchor),
              self.bottomLabel.bottomAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
              self.bottomLabel.centerXAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.centerXAnchor),
            ])
          }

          override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
            self.topLabel.font = .preferredFont(
              forTextStyle: .headline, compatibleWith: self.traitCollection)
            self.leadingLabel.font = .preferredFont(
              forTextStyle: .body, compatibleWith: self.traitCollection)
            self.trailingLabel.font = .preferredFont(
              forTextStyle: .body, compatibleWith: self.traitCollection)
            self.bottomLabel.font = .preferredFont(
              forTextStyle: .subheadline, compatibleWith: self.traitCollection)
            self.view.setNeedsUpdateConstraints()
            self.view.updateConstraintsIfNeeded()
          }
        }

        let myViewController = MyViewController()
        let navController = UINavigationController(rootViewController: myViewController)
        let viewController = UITabBarController()
        viewController.setViewControllers([navController], animated: false)

        assertSnapshot(of: viewController, as: .image(on: .iPhoneSe), named: "iphone-se")
        assertSnapshot(of: viewController, as: .image(on: .iPhone8), named: "iphone-8")
        assertSnapshot(of: viewController, as: .image(on: .iPhone8Plus), named: "iphone-8-plus")
        assertSnapshot(of: viewController, as: .image(on: .iPhoneX), named: "iphone-x")
        assertSnapshot(of: viewController, as: .image(on: .iPhoneXr), named: "iphone-xr")
        assertSnapshot(of: viewController, as: .image(on: .iPhoneXsMax), named: "iphone-xs-max")
        assertSnapshot(of: viewController, as: .image(on: .iPadMini), named: "ipad-mini")
        assertSnapshot(of: viewController, as: .image(on: .iPad9_7), named: "ipad-9-7")
        assertSnapshot(of: viewController, as: .image(on: .iPad10_2), named: "ipad-10-2")
        assertSnapshot(of: viewController, as: .image(on: .iPadPro10_5), named: "ipad-pro-10-5")
        assertSnapshot(of: viewController, as: .image(on: .iPadPro11), named: "ipad-pro-11")
        assertSnapshot(of: viewController, as: .image(on: .iPadPro12_9), named: "ipad-pro-12-9")

        assertSnapshot(of: viewController, as: .image(on: .iPhoneSe(.portrait)), named: "iphone-se")
        assertSnapshot(of: viewController, as: .image(on: .iPhone8(.portrait)), named: "iphone-8")
        assertSnapshot(
          of: viewController, as: .image(on: .iPhone8Plus(.portrait)), named: "iphone-8-plus")
        assertSnapshot(of: viewController, as: .image(on: .iPhoneX(.portrait)), named: "iphone-x")
        assertSnapshot(of: viewController, as: .image(on: .iPhoneXr(.portrait)), named: "iphone-xr")
        assertSnapshot(
          of: viewController, as: .image(on: .iPhoneXsMax(.portrait)), named: "iphone-xs-max")
        assertSnapshot(
          of: viewController, as: .image(on: .iPadMini(.landscape)), named: "ipad-mini")
        assertSnapshot(of: viewController, as: .image(on: .iPad9_7(.landscape)), named: "ipad-9-7")
        assertSnapshot(
          of: viewController, as: .image(on: .iPad10_2(.landscape)), named: "ipad-10-2")
        assertSnapshot(
          of: viewController, as: .image(on: .iPadPro10_5(.landscape)), named: "ipad-pro-10-5")
        assertSnapshot(
          of: viewController, as: .image(on: .iPadPro11(.landscape)), named: "ipad-pro-11")
        assertSnapshot(
          of: viewController, as: .image(on: .iPadPro12_9(.landscape)), named: "ipad-pro-12-9")

        assertSnapshot(
          of: viewController, as: .image(on: .iPhoneSe(.landscape)), named: "iphone-se-alternative")
        assertSnapshot(
          of: viewController, as: .image(on: .iPhone8(.landscape)), named: "iphone-8-alternative")
        assertSnapshot(
          of: viewController, as: .image(on: .iPhone8Plus(.landscape)),
          named: "iphone-8-plus-alternative")
        assertSnapshot(
          of: viewController, as: .image(on: .iPhoneX(.landscape)), named: "iphone-x-alternative")
        assertSnapshot(
          of: viewController, as: .image(on: .iPhoneXr(.landscape)), named: "iphone-xr-alternative")
        assertSnapshot(
          of: viewController, as: .image(on: .iPhoneXsMax(.landscape)),
          named: "iphone-xs-max-alternative")
        assertSnapshot(
          of: viewController, as: .image(on: .iPadMini(.portrait)), named: "ipad-mini-alternative")
        assertSnapshot(
          of: viewController, as: .image(on: .iPad9_7(.portrait)), named: "ipad-9-7-alternative")
        assertSnapshot(
          of: viewController, as: .image(on: .iPad10_2(.portrait)), named: "ipad-10-2-alternative")
        assertSnapshot(
          of: viewController, as: .image(on: .iPadPro10_5(.portrait)),
          named: "ipad-pro-10-5-alternative")
        assertSnapshot(
          of: viewController, as: .image(on: .iPadPro11(.portrait)),
          named: "ipad-pro-11-alternative")
        assertSnapshot(
          of: viewController, as: .image(on: .iPadPro12_9(.portrait)),
          named: "ipad-pro-12-9-alternative")
      }
    #endif
  }

  func testCollectionViewsWithMultipleScreenSizes() {
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
              equalTo: view.layoutMarginsGuide.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
          ])

          collectionView.reloadData()
        }

        override func viewDidLayoutSubviews() {
          super.viewDidLayoutSubviews()
          collectionView.collectionViewLayout.invalidateLayout()
        }

        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
          super.traitCollectionDidChange(previousTraitCollection)
          collectionView.collectionViewLayout.invalidateLayout()
        }

        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath)
          -> UICollectionViewCell
        {
          let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
          cell.contentView.backgroundColor = .orange
          return cell
        }

        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int)
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

      assertSnapshots(
        of: viewController,
        as: [
          "ipad": .image(on: .iPadPro12_9),
          "iphoneSe": .image(on: .iPhoneSe),
          "iphone8": .image(on: .iPhone8),
          "iphoneMax": .image(on: .iPhoneXsMax),
        ])
    #endif
  }

  func testTraitsWithView() {
    #if os(iOS)
      if #available(iOS 11.0, *) {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title1)
        label.adjustsFontForContentSizeCategory = true
        label.text = "What's the point?"

        allContentSizes.forEach { name, contentSize in
          assertSnapshot(
            of: label,
            as: .image(traits: .init(preferredContentSizeCategory: contentSize)),
            named: "label-\(name)"
          )
        }
      }
    #endif
  }

  func testTraitsWithViewController() {
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
          equalTo: viewController.view.layoutMarginsGuide.leadingAnchor),
        label.topAnchor.constraint(equalTo: viewController.view.layoutMarginsGuide.topAnchor),
        label.trailingAnchor.constraint(
          equalTo: viewController.view.layoutMarginsGuide.trailingAnchor),
      ])

      allContentSizes.forEach { name, contentSize in
        assertSnapshot(
          of: viewController,
          as: .recursiveDescription(
            on: .iPhoneSe, traits: .init(preferredContentSizeCategory: contentSize)),
          named: "label-\(name)"
        )
      }
    #endif
  }

#if os(iOS) || os(tvOS)
  func testUIBezierPath() {
    let path = UIBezierPath.heart
    assertSnapshot(of: path, as: .image, named: platform)
    assertSnapshot(of: path, as: .elementsDescription, named: platform)
  }
#endif

#if os(iOS)
  func testUIView() {
    let view = UIButton(type: .contactAdd)
    assertSnapshot(of: view, as: .image)
    assertSnapshot(of: view, as: .recursiveDescription)
  }
#endif

  func testUIViewControllerLifeCycle() {
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

      assertSnapshot(of: viewController, as: .image)

      wait(for: [
        viewController.viewDidLoadExpectation,
        viewController.viewWillAppearExpectation,
        viewController.viewDidAppearExpectation,
        viewController.viewWillDisappearExpectation,
        viewController.viewDidDisappearExpectation,
      ], timeout: 10, enforceOrder: true)
    #endif
  }

  func testCALayer() {
    #if os(iOS)
      let layer = CALayer()
      layer.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
      layer.backgroundColor = UIColor.red.cgColor
      layer.borderWidth = 4.0
      layer.borderColor = UIColor.black.cgColor
      assertSnapshot(of: layer, as: .image)
    #endif
  }

  func testCALayerWithGradient() {
    #if os(iOS)
      let baseLayer = CALayer()
      baseLayer.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
      let gradientLayer = CAGradientLayer()
      gradientLayer.colors = [UIColor.red.cgColor, UIColor.yellow.cgColor]
      gradientLayer.frame = baseLayer.frame
      baseLayer.addSublayer(gradientLayer)
      assertSnapshot(of: baseLayer, as: .image)
    #endif
  }

  func testViewControllerHierarchy() {
    #if os(iOS)
      let page = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
      page.setViewControllers([UIViewController()], direction: .forward, animated: false)
      let tab = UITabBarController()
      tab.viewControllers = [
        UINavigationController(rootViewController: page),
        UINavigationController(rootViewController: UIViewController()),
        UINavigationController(rootViewController: UIViewController()),
        UINavigationController(rootViewController: UIViewController()),
        UINavigationController(rootViewController: UIViewController()),
      ]
      assertSnapshot(of: tab, as: .hierarchy)
    #endif
  }

  func testURLRequest() {
    var get = URLRequest(url: URL(string: "https://www.pointfree.co/")!)
    get.addValue("pf_session={}", forHTTPHeaderField: "Cookie")
    get.addValue("text/html", forHTTPHeaderField: "Accept")
    get.addValue("application/json", forHTTPHeaderField: "Content-Type")
    assertSnapshot(of: get, as: .raw, named: "get")
    assertSnapshot(of: get, as: .curl, named: "get-curl")

    var getWithQuery = URLRequest(
      url: URL(string: "https://www.pointfree.co?key_2=value_2&key_1=value_1&key_3=value_3")!)
    getWithQuery.addValue("pf_session={}", forHTTPHeaderField: "Cookie")
    getWithQuery.addValue("text/html", forHTTPHeaderField: "Accept")
    getWithQuery.addValue("application/json", forHTTPHeaderField: "Content-Type")
    assertSnapshot(of: getWithQuery, as: .raw, named: "get-with-query")
    assertSnapshot(of: getWithQuery, as: .curl, named: "get-with-query-curl")

    var post = URLRequest(url: URL(string: "https://www.pointfree.co/subscribe")!)
    post.httpMethod = "POST"
    post.addValue("pf_session={\"user_id\":\"0\"}", forHTTPHeaderField: "Cookie")
    post.addValue("text/html", forHTTPHeaderField: "Accept")
    post.httpBody = Data("pricing[billing]=monthly&pricing[lane]=individual".utf8)
    assertSnapshot(of: post, as: .raw, named: "post")
    assertSnapshot(of: post, as: .curl, named: "post-curl")

    var postWithJSON = URLRequest(
      url: URL(string: "http://dummy.restapiexample.com/api/v1/create")!)
    postWithJSON.httpMethod = "POST"
    postWithJSON.addValue("application/json", forHTTPHeaderField: "Content-Type")
    postWithJSON.addValue("application/json", forHTTPHeaderField: "Accept")
    postWithJSON.httpBody = Data(
      "{\"name\":\"tammy134235345235\", \"salary\":0, \"age\":\"tammy133\"}".utf8)
    assertSnapshot(of: postWithJSON, as: .raw, named: "post-with-json")
    assertSnapshot(of: postWithJSON, as: .curl, named: "post-with-json-curl")

    var head = URLRequest(url: URL(string: "https://www.pointfree.co/")!)
    head.httpMethod = "HEAD"
    head.addValue("pf_session={}", forHTTPHeaderField: "Cookie")
    assertSnapshot(of: head, as: .raw, named: "head")
    assertSnapshot(of: head, as: .curl, named: "head-curl")

    post = URLRequest(url: URL(string: "https://www.pointfree.co/subscribe")!)
    post.httpMethod = "POST"
    post.addValue("pf_session={\"user_id\":\"0\"}", forHTTPHeaderField: "Cookie")
    post.addValue("application/json", forHTTPHeaderField: "Accept")
    post.httpBody = Data(
      """
      {"pricing": {"lane": "individual","billing": "monthly"}}
      """.utf8)
  }

  #if os(iOS) || os(macOS) || os(tvOS)
    func testSnapshotWithZeroHeight_whenNoReferenceImage() {
      let size = CGSize(width: 350, height: 0)
      let view = XView(frame: .init(origin: .zero, size: size))
      let message = verifySnapshot(of: view, as: .image)
      XCTAssertEqual(message, "Snapshot is empty")
    }

    func testSnapshotWithZeroWidth_whenNoReferenceImage() {
      let size = CGSize(width: 0, height: 350)
      let view = XView(frame: .init(origin: .zero, size: size))
      let message = verifySnapshot(of: view, as: .image)
      XCTAssertEqual(message, "Snapshot is empty")
    }

    func testSnapshotWithZeroSize_whenNoReferenceImage() {
      let view = XView(frame: .zero)
      let message = verifySnapshot(of: view, as: .image)
      XCTAssertEqual(message, "Snapshot is empty")
    }

    func testSnapshotWithZeroSize_whenReferenceImageExists() {
      let view = XView(frame: .zero)
      let message = verifySnapshot(of: view, as: .image)
      XCTAssertEqual(message, "Snapshot is empty")
    }

    func testSnapshotWithUnequalSize() {
      let size = CGSize(width: 100, height: 100)
      let view = XView(frame: .init(origin: .zero, size: size))
      var message = verifySnapshot(of: view, as: .image, named: platform)
      XCTAssertNil(message)
      let newSize = CGSize(width: 123, height: 123)
      view.frame = .init(origin: .zero, size: newSize)
      message = verifySnapshot(of: view, as: .image, named: platform)
      let firstLine = message?.split(whereSeparator: \.isNewline).first
      #if os(iOS)
      XCTAssertEqual(firstLine, "[ios] Snapshot size (246.0, 246.0) is unequal to expected size (200.0, 200.0)")
      #elseif os(macOS)
      XCTAssertEqual(firstLine, "[macos] Snapshot size (123.0, 123.0) is unequal to expected size (100.0, 100.0)")
      #endif
    }

    func testImageSnapshot_whenReferenceImageLoadingFails() {
      let size = CGSize(width: 100, height: 100)
      let view = XView(frame: .init(origin: .zero, size: size))
      let message = verifySnapshot(of: view, as: .image)
      XCTAssertEqual(message, "Invalid image data")
    }
  #endif

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
  func testSwiftUIView() {
    let view = SwiftUIView()
    assertSnapshot(of: view, as: .image(layout: .fixed(width: 100, height: 100)), named: "\(platform)\(osVersion.majorVersion)-fixed")
    assertSnapshot(of: view, as: .image(layout: .sizeThatFits), named: "\(platform)\(osVersion.majorVersion)-size-that-fits")
  }
#endif

#if os(iOS)
  func testSwiftUIView() {
    let view = SwiftUIView()
    assertSnapshot(of: view, as: .image(layout: .fixed(width: 100, height: 100), traits: .init(userInterfaceStyle: .light)), named: "\(platform)-fixed")
    assertSnapshot(of: view, as: .image(layout: .sizeThatFits, traits: .init(userInterfaceStyle: .light)), named: "\(platform)-size-that-fits")
    assertSnapshot(of: view, as: .image(layout: .device(config: .iPhoneSe), traits: .init(userInterfaceStyle: .light)), named: "\(platform)-device")
  }
#endif

#if os(tvOS)
  func testSwiftUIView() {
    let view = SwiftUIView()
    assertSnapshot(of: view, as: .image(layout: .fixed(width: 100, height: 100)), named: "\(platform)-fixed")
    assertSnapshot(of: view, as: .image(layout: .sizeThatFits), named: "\(platform)-size-that-fits")
    assertSnapshot(of: view, as: .image(layout: .device(config: .tv)), named: "\(platform)-device")
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
      "accessibility-extra-extra-extra-large": .accessibilityExtraExtraExtraLarge,
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
