import Foundation
import SnapshotTesting
import Testing

@Suite(.snapshots(record: .failed, diffTool: .ksdiff))
struct DumpTests {
  @Test func `object dump`() async {
    struct User { let id: Int, name: String, bio: String }
    let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")
    await assertSnapshot(of: user, as: .dump)
  }

  @Test func `recursive dump`() async {
    await withSnapshotTesting {
      class Father {
        var child: Child?
        init(_ child: Child? = nil) { self.child = child }
      }
      class Child {
        let father: Father
        init(_ father: Father) {
          self.father = father
          father.child = self
        }
      }
      let father = Father()
      let child = Child(father)
      await assertSnapshot(of: father, as: .dump)
      await assertSnapshot(of: child, as: .dump)
    }
  }

  @Test func `StringConvertible dump`() async {
    await assertSnapshot(of: "a" as Character, as: .dump, named: "character")
    await assertSnapshot(of: Data("Hello, world!".utf8), as: .dump, named: "data")
    await assertSnapshot(of: Date(timeIntervalSinceReferenceDate: 0), as: .dump, named: "date")
    await assertSnapshot(of: NSObject(), as: .dump, named: "nsobject")
    await assertSnapshot(of: "Hello, world!", as: .dump, named: "string")
    await assertSnapshot(of: "Hello, world!".dropLast(8), as: .dump, named: "substring")
    await assertSnapshot(of: URL(string: "https://www.apple.com")!, as: .dump, named: "url")
  }

  @Test func `Dictionary and Set dump`() async {
    struct Person: Hashable { let name: String }
    struct DictionarySetContainer { let dict: [String: Int], set: Set<Person> }
    let set = DictionarySetContainer(
      dict: ["c": 3, "a": 1, "b": 2],
      set: [.init(name: "Bob"), .init(name: "John")]
    )
    await assertSnapshot(of: set, as: .dump)
  }

  @Test func `multiple dumps`() async {
    await assertSnapshot(of: [1], as: .dump)
    await assertSnapshot(of: [1, 2], as: .dump)
  }

  @Test func `named dump`() async {
    struct User { let id: Int, name: String, bio: String }
    let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")
    await assertSnapshot(of: user, as: .dump, named: "named")
  }
}
