#if os(macOS)
  import Cocoa
  typealias XImage = NSImage
  typealias ImageView = NSImageView
  typealias View = NSView
#elseif os(iOS) || os(tvOS)
  import UIKit
  typealias XImage = UIImage
  typealias ImageView = UIImageView
  typealias View = UIView
#endif
