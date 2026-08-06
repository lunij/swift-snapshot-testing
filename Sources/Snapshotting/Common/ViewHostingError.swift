#if os(iOS) || os(tvOS)
import Foundation

enum ViewHostingError: Error, Equatable {
  case keyWindowUnavailable
}

extension ViewHostingError: LocalizedError {
  var errorDescription: String? {
    switch self {
    case .keyWindowUnavailable:
      return "There is no key window to draw into, tests being run without a host application"
    }
  }
}
#endif
