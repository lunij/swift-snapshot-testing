#if os(iOS) || os(macOS) || os(tvOS)
import Foundation
import Snapshotting
import Testing

#if canImport(SceneKit)
import SceneKit
#endif
#if canImport(SpriteKit)
import SpriteKit
#endif

@MainActor
struct MetalViewTests {
  @Test func `scenekit view`() async {
    let scene = SCNScene()

    let sphereGeometry = SCNSphere(radius: 3)
    sphereGeometry.segmentCount = 200
    let sphereNode = SCNNode(geometry: sphereGeometry)
    sphereNode.position = SCNVector3Zero
    scene.rootNode.addChildNode(sphereNode)

    sphereGeometry.firstMaterial?.diffuse.contents = URL(filePath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appending(path: "__Fixtures__/earth.png")

    let cameraNode = SCNNode()
    cameraNode.camera = SCNCamera()
    cameraNode.position = SCNVector3Make(0, 0, 8)
    scene.rootNode.addChildNode(cameraNode)

    let omniLight = SCNLight()
    omniLight.type = .omni
    let omniLightNode = SCNNode()
    omniLightNode.light = omniLight
    omniLightNode.position = SCNVector3Make(10, 10, 10)
    scene.rootNode.addChildNode(omniLightNode)

    await expectSnapshot(
      of: scene,
      as: .image(precision: 0.999, size: .init(width: 500, height: 500))
    )
  }

  @Test func `spritekit view`() async {
    let scene = SKScene(size: .init(width: 50, height: 50))
    let node = SKShapeNode(circleOfRadius: 15)
    node.fillColor = .red
    node.position = .init(x: 25, y: 25)
    scene.addChild(node)

    await expectSnapshot(
      of: scene,
      as: .image(size: .init(width: 50, height: 50))
    )
  }
}
#endif
