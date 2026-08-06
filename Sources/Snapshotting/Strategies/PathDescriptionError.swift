#if os(iOS) || os(macOS) || os(tvOS)
import CoreGraphics
import Foundation

enum PathDescriptionError: Error {
  case coordinateNotFormattable(CGFloat)
}

extension PathDescriptionError: LocalizedError {
  var errorDescription: String? {
    switch self {
    case .coordinateNotFormattable(let coordinate):
      return "Path coordinate \(coordinate) could not be formatted"
    }
  }
}
#endif
