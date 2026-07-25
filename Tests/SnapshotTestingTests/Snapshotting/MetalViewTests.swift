import Foundation
import XCTest

@testable import SnapshotTesting

#if canImport(SceneKit)
import SceneKit
#endif
#if canImport(SpriteKit)
import SpriteKit
#endif

final class MetalViewTests: BaseTestCase {
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
}
