#if os(iOS) || os(macOS) || os(tvOS) || os(visionOS)
import Foundation

enum ImageConversionError: Error {
  case cgImageConversionFailed
  case invalidImageData
  case pngDataConversionFailed
  case zeroHeight
  case zeroSize
  case zeroWidth
}

extension ImageConversionError: LocalizedError {
  var errorDescription: String? {
    switch self {
    case .cgImageConversionFailed, .pngDataConversionFailed:
      return "Snapshot could not be processed"
    case .invalidImageData:
      return "Invalid image data"
    case .zeroHeight:
      return "Snapshot has a height of zero"
    case .zeroSize:
      return "Snapshot is empty"
    case .zeroWidth:
      return "Snapshot has a width of zero"
    }
  }
}
#endif
