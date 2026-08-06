#if os(iOS) || os(macOS) || os(tvOS)
import Foundation

enum RuntimeDescriptionError: Error, Equatable {
  case selectorUnavailable(String)
  case descriptionNotText(String)
}

extension RuntimeDescriptionError: LocalizedError {
  var errorDescription: String? {
    switch self {
    case .selectorUnavailable(let selector):
      return "'\(selector)' is not implemented by what is being snapshot"
    case .descriptionNotText(let selector):
      return "'\(selector)' answered with something other than text"
    }
  }
}
#endif
