import Foundation
import XCTest

@testable import SnapshotTesting

final class DumpTests: BaseTestCase {
  func testAny() async {
    struct User { let id: Int, name: String, bio: String }
    let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")
    await assertSnapshot(of: user, as: .dump)
  }

  func testRecursion() async {
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

  func testAnySnapshotStringConvertible() async {
    await assertSnapshot(of: "a" as Character, as: .dump, named: "character")
    await assertSnapshot(of: Data("Hello, world!".utf8), as: .dump, named: "data")
    await assertSnapshot(of: Date(timeIntervalSinceReferenceDate: 0), as: .dump, named: "date")
    await assertSnapshot(of: NSObject(), as: .dump, named: "nsobject")
    await assertSnapshot(of: "Hello, world!", as: .dump, named: "string")
    await assertSnapshot(of: "Hello, world!".dropLast(8), as: .dump, named: "substring")
    await assertSnapshot(of: URL(string: "https://www.pointfree.co")!, as: .dump, named: "url")
  }

  func testDeterministicDictionaryAndSetSnapshots() async {
    struct Person: Hashable { let name: String }
    struct DictionarySetContainer { let dict: [String: Int], set: Set<Person> }
    let set = DictionarySetContainer(
      dict: ["c": 3, "a": 1, "b": 2],
      set: [.init(name: "Brandon"), .init(name: "Stephen")]
    )
    await assertSnapshot(of: set, as: .dump)
  }

  func testMultipleSnapshots() async {
    await assertSnapshot(of: [1], as: .dump)
    await assertSnapshot(of: [1, 2], as: .dump)
  }

  func testNamedAssertion() async {
    struct User { let id: Int, name: String, bio: String }
    let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")
    await assertSnapshot(of: user, as: .dump, named: "named")
  }
}
