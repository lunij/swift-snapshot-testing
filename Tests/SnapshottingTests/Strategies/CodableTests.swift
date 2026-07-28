import Foundation
import Snapshotting
import Testing

struct CodableTests {
  @Test func `Any as JSON`() async throws {
    struct User: Encodable { let id: Int, name: String, bio: String }
    let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")

    let data = try JSONEncoder().encode(user)
    let any = try JSONSerialization.jsonObject(with: data, options: [])

    await expectSnapshot(of: any, as: .json)
  }

  @Test func `Data snapshot`() async {
    let data = Data([0xDE, 0xAD, 0xBE, 0xEF])

    await expectSnapshot(of: data, as: .data)
  }

  @Test func `Encodable snapshot`() async {
    struct User: Encodable { let id: Int, name: String, bio: String }
    let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")

    await expectSnapshot(of: user, as: .json)
    await expectSnapshot(of: user, as: .plist)
  }
}
