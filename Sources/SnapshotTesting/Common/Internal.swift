#if os(macOS)
  import Cocoa
  typealias XImage = NSImage
  typealias XImageView = NSImageView
  typealias XView = NSView
#elseif os(iOS) || os(tvOS)
  import UIKit
  typealias XImage = UIImage
  typealias XImageView = UIImageView
  typealias XView = UIView
#endif
