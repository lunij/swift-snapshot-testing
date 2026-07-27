import Foundation
import SnapshotTesting
import Testing

@Suite(.snapshots(record: .failed, diffTool: .ksdiff))
struct CodableTests {
  @Test func `Any as JSON`() async throws {
    struct User: Encodable { let id: Int, name: String, bio: String }
    let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")

    let data = try JSONEncoder().encode(user)
    let any = try JSONSerialization.jsonObject(with: data, options: [])

    await assertSnapshot(of: any, as: .json)
  }

  @Test func `Data snapshot`() async {
    let data = Data([0xDE, 0xAD, 0xBE, 0xEF])

    await assertSnapshot(of: data, as: .data)
  }

  @Test func `Encodable snapshot`() async {
    struct User: Encodable { let id: Int, name: String, bio: String }
    let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")

    await assertSnapshot(of: user, as: .json)
    await assertSnapshot(of: user, as: .plist)
  }
}
