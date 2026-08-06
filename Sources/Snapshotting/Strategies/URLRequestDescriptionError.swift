#if !os(WASI)
import Foundation

enum URLRequestDescriptionError: Error, Equatable {
  case urlMissing
}

extension URLRequestDescriptionError: LocalizedError {
  var errorDescription: String? {
    switch self {
    case .urlMissing:
      return "The request being snapshot has no URL"
    }
  }
}
#endif
