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

  func attachments(_ old: XImage, _ new: XImage, _ diff: XImage) -> [XCTAttachment] {
      [
        XCTAttachment(name: "reference", image: old),
        XCTAttachment(name: "failure", image: new),
        XCTAttachment(name: "difference", image: diff)
      ]
  }
#endif
