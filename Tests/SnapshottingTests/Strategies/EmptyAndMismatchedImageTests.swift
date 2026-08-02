#if os(iOS) || os(macOS) || os(tvOS)
import Foundation
import Testing

@testable import Snapshotting

@MainActor
struct EmptyAndMismatchedImageTests {
  @Test func `image with zero height`() async {
    let size = CGSize(width: 350, height: 0)
    let view = XView(frame: .init(origin: .zero, size: size))
    let result = await snapshotResult(of: view, as: .image)
    #expect(result.outcome == .errored("Snapshot is empty"))
  }

  @Test func `image with zero width`() async {
    let size = CGSize(width: 0, height: 350)
    let view = XView(frame: .init(origin: .zero, size: size))
    let result = await snapshotResult(of: view, as: .image)
    #expect(result.outcome == .errored("Snapshot is empty"))
  }

  @Test func `image with zero size`() async {
    let view = XView(frame: .zero)
    let result = await snapshotResult(of: view, as: .image)
    #expect(result.outcome == .errored("Snapshot is empty"))
  }

  @Test func `image with size mismatch`() async {
    let size = CGSize(width: 100, height: 100)
    let view = XView(frame: .init(origin: .zero, size: size))
    var result = await snapshotResult(of: view, as: .image, named: platform)
    #expect(result.outcome == .matched)
    let newSize = CGSize(width: 123, height: 123)
    view.frame = .init(origin: .zero, size: newSize)
    result = await snapshotResult(of: view, as: .image, named: platform, record: .never)
    #expect(result.name == platform)
    // The reason counts pixels, so the sizes above arrive multiplied by the scale the strategy
    // rendered at. Deriving them keeps this pinned to the scale policy rather than to a list of
    // platforms.
    let scale = Int(SnapshotScale.default)
    #expect(
      result.outcome.mismatch?.reason
        == """
        Image size \(Int(newSize.width) * scale)×\(Int(newSize.height) * scale) \
        does not match reference size \(Int(size.width) * scale)×\(Int(size.height) * scale).
        """
    )
  }
}
#endif
