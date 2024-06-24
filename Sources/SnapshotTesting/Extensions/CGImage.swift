#if os(iOS) || os(macOS) || os(tvOS) || os(visionOS)
import CoreGraphics

extension CGImage {
    var size: CGSize {
        .init(width: width, height: height)
    }
}
#endif
