#if os(iOS) || os(macOS) || os(tvOS)
import CoreGraphics

extension CGImage {
    var size: CGSize {
        .init(width: width, height: height)
    }
}
#endif
