#if os(iOS) || os(macOS) || os(tvOS)
import Foundation

enum ImageConversionError: Error {
  case cgImageConversionFailed
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
