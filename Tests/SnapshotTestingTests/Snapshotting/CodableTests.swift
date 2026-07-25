import Foundation
import XCTest

@testable import SnapshotTesting

final class CodableTests: BaseTestCase {
  @available(macOS 10.13, tvOS 11.0, *)
  func testAnyAsJson() async throws {
    struct User: Encodable { let id: Int, name: String, bio: String }
    let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")

    let data = try JSONEncoder().encode(user)
    let any = try JSONSerialization.jsonObject(with: data, options: [])

    await assertSnapshot(of: any, as: .json)
  }

  func testData() async {
    let data = Data([0xDE, 0xAD, 0xBE, 0xEF])

    await assertSnapshot(of: data, as: .data)
  }

  func testEncodable() async {
    struct User: Encodable { let id: Int, name: String, bio: String }
    let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")

    if #available(iOS 11.0, macOS 10.13, tvOS 11.0, *) {
      await assertSnapshot(of: user, as: .json)
    }
    await assertSnapshot(of: user, as: .plist)
  }
}
