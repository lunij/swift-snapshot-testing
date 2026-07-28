import Foundation
import Snapshotting
import Testing

struct DumpTests {
  @Test func `object dump`() async {
    struct User { let id: Int, name: String, bio: String }
    let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")
    await expectSnapshot(of: user, as: .dump)
  }

  @Test func `recursive dump`() async {
    await withSnapshotConfiguration {
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
      await expectSnapshot(of: father, as: .dump, named: "father")
      await expectSnapshot(of: child, as: .dump, named: "child")
    }
  }

  @Test func `StringConvertible dump`() async {
    await expectSnapshot(of: "a" as Character, as: .dump, named: "character")
    await expectSnapshot(of: Data("Hello, world!".utf8), as: .dump, named: "data")
    await expectSnapshot(of: Date(timeIntervalSinceReferenceDate: 0), as: .dump, named: "date")
    await expectSnapshot(of: NSObject(), as: .dump, named: "nsobject")
    await expectSnapshot(of: "Hello, world!", as: .dump, named: "string")
    await expectSnapshot(of: "Hello, world!".dropLast(8), as: .dump, named: "substring")
    await expectSnapshot(of: URL(string: "https://www.apple.com")!, as: .dump, named: "url")
  }

  @Test func `Dictionary and Set dump`() async {
    struct Person: Hashable { let name: String }
    struct DictionarySetContainer { let dict: [String: Int], set: Set<Person> }
    let set = DictionarySetContainer(
      dict: ["c": 3, "a": 1, "b": 2],
      set: [.init(name: "Bob"), .init(name: "John")]
    )
    await expectSnapshot(of: set, as: .dump)
  }

  @Test func `multiple dumps`() async {
    await expectSnapshot(of: [1], as: .dump, named: "one element")
    await expectSnapshot(of: [1, 2], as: .dump, named: "two elements")
  }

  @Test func `named dump`() async {
    struct User { let id: Int, name: String, bio: String }
    let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")
    await expectSnapshot(of: user, as: .dump, named: "named")
  }
}
