import Foundation

extension Data {
#if os(iOS) || os(tvOS)
    func image(scale: CGFloat) throws -> XImage {
        let image = XImage(data: self, scale: scale)
        guard let image else {
            throw ImageConversionError.invalidImageData
        }
        return image
    }
#elseif os(macOS)
    func image() throws -> XImage {
        let image = XImage(data: self)
        guard let image else {
            throw ImageConversionError.invalidImageData
        }
        return image
    }
#endif
}
