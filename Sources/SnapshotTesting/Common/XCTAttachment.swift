#if os(Linux) || os(Windows)
  import Foundation

  public struct XCTAttachment {
    public init(data: Data) {}
    public init(data: Data, uniformTypeIdentifier: String) {}
  }
#else
  import XCTest

  extension XCTAttachment {
    convenience init(name: String, image: XImage) {
      self.init(image: image)
      self.name = name
    }
  }
#endif
