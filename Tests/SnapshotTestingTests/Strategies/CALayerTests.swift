#if os(iOS)
import SnapshotTesting
import Testing
import UIKit

@Suite(.snapshots(record: .failed, diffTool: .ksdiff))
struct CALayerTests {
  @Test func `CALayer with colors`() async {
    let layer = CALayer()
    layer.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
    layer.backgroundColor = UIColor.red.cgColor
    layer.borderWidth = 4.0
    layer.borderColor = UIColor.black.cgColor
    await assertSnapshot(of: layer, as: .image)
  }

  @Test func `CALayer with gradient`() async {
    let baseLayer = CALayer()
    baseLayer.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
    let gradientLayer = CAGradientLayer()
    gradientLayer.colors = [UIColor.red.cgColor, UIColor.yellow.cgColor]
    gradientLayer.frame = baseLayer.frame
    baseLayer.addSublayer(gradientLayer)
    await assertSnapshot(of: baseLayer, as: .image)
  }
}
#endif
