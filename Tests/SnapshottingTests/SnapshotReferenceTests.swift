import Foundation
import Snapshotting
import Testing

struct SnapshotReferenceTests {
  @Test func `a base and a format name a file`() {
    let reference = SnapshotReference(base: "a view", pathExtension: "png", in: directory)

    #expect(reference.url == directory.appending(path: "a-view.png"))
    #expect(reference.name == "a-view.png")
  }

  @Test func `a format that needs no extension leaves the name bare`() {
    #expect(SnapshotReference(base: "a value", in: directory).name == "a-value")
  }

  @Test func `the strategy identifier follows the base`() {
    let reference = SnapshotReference(
      base: "a view",
      strategyIdentifier: "recursive-description",
      pathExtension: "txt",
      in: directory
    )

    #expect(reference.name == "a-view.recursive-description.txt")
  }

  @Test func `qualifiers follow the strategy identifier in the order they are given`() {
    let reference = SnapshotReference(
      base: "a view",
      strategyIdentifier: "hierarchy",
      qualifiers: ["dark", "2"],
      pathExtension: "txt",
      in: directory
    )

    #expect(reference.name == "a-view.hierarchy.dark.2.txt")
  }

  @Test func `qualifiers stand on their own when the format speaks for itself`() {
    let reference = SnapshotReference(
      base: "a view",
      qualifiers: ["dark"],
      pathExtension: "png",
      in: directory
    )

    #expect(reference.name == "a-view.dark.png")
  }

  @Test(arguments: [
    ("Encodable snapshot()", "Encodable-snapshot"),
    ("a/b", "a-b"),
    ("  padded  ", "padded"),
    ("already-sanitized", "already-sanitized")
  ])
  func `a component is reduced to what can name a file`(component: String, sanitized: String) {
    #expect(SnapshotReference(base: component, in: directory).name == sanitized)
    #expect(
      SnapshotReference(base: "a view", qualifiers: [component], in: directory).name
        == "a-view.\(sanitized)"
    )
  }

  /// A caller that cannot describe a qualifier hands over what it has, and an empty component would
  /// otherwise leave a name with two separators running together.
  @Test(arguments: ["", " ", "/"])
  func `a qualifier that names nothing is left out`(qualifier: String) {
    let reference = SnapshotReference(
      base: "a view",
      qualifiers: [qualifier, "dark"],
      pathExtension: "png",
      in: directory
    )

    #expect(reference.name == "a-view.dark.png")
  }

  @Test func `two references to one file are the same reference`() {
    let reference = SnapshotReference(base: "a view", qualifiers: ["dark"], in: directory)
    let same = SnapshotReference(base: "a view", qualifiers: ["dark"], in: directory)
    let other = SnapshotReference(base: "a view", qualifiers: ["light"], in: directory)

    #expect(reference == same)
    #expect(reference != other)
  }
}

// MARK: - Private

private let directory = URL(filePath: "/references", directoryHint: .isDirectory)
