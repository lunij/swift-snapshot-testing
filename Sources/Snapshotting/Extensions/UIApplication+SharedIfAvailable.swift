#if os(iOS) || os(tvOS)
import UIKit

extension UIApplication {
  @MainActor static var sharedIfAvailable: UIApplication? {
    let sharedSelector = NSSelectorFromString("sharedApplication")
    guard UIApplication.responds(to: sharedSelector) else {
      return nil
    }

    let shared = UIApplication.perform(sharedSelector)
    return shared?.takeUnretainedValue() as? UIApplication
  }
}
#endif
