#if os(iOS) || os(macOS) || os(tvOS)
import Snapshotting
import Testing

#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

/// Every reference here is shared by the platforms the test runs on: a path is written in the
/// coordinates of whatever authored it, and drawn through Core Graphics at a scale the strategy
/// names, so nothing about the recording is left to the machine that made it.
struct BezierPathTests {
  @Test func `CGPath snapshot`() async {
    let path = CGPath.heart
    await expectSnapshot(of: path, as: .image)
    await expectSnapshot(of: path, as: .elementsDescription)
  }

  #if os(macOS)
  @Test func `NSBezierPath snapshot`() async {
    let path = NSBezierPath.heart
    await expectSnapshot(of: path, as: .image)
    await expectSnapshot(of: path, as: .elementsDescription)
  }

  /// The heart is drawn with cubic curves, so nothing else says what a quadratic one is called. It
  /// takes the name a `CGPath` gives the same geometry, both its points being the same two.
  @Test func `a quadratic curve is named like a path's own`() async throws {
    let path = NSBezierPath()
    path.move(to: .zero)
    path.curve(to: CGPoint(x: 10, y: 0), controlPoint: CGPoint(x: 5, y: 10))

    let strategy = SnapshotStrategy<NSBezierPath, String>.elementsDescription
    #expect(
      try await strategy.snapshot(path) == """
        MoveTo (0.0, 0.0)
        QuadCurveTo (5.0, 10.0) (10.0, 0.0)

        """
    )
  }
  #endif

  #if os(iOS) || os(tvOS)
  @Test func `UIBezierPath snapshot`() async {
    let path = UIBezierPath.heart
    await expectSnapshot(of: path, as: .image)
    await expectSnapshot(of: path, as: .elementsDescription)
  }
  #endif
}
#endif
