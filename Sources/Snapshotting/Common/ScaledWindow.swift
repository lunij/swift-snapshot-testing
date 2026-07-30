#if os(macOS)
import Cocoa

/// A window that reports a fixed 2x backing scale factor, so views hosted in it
/// render at Retina resolution regardless of the display the tests run on.
final class ScaledWindow: NSWindow {
  override var backingScaleFactor: CGFloat {
    2
  }
}
#endif
