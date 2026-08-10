import Foundation
import Testing

@testable import Snapshotting

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

  // MARK: Platforms

  @Test func `a name no file answers to is shared by every platform`() throws {
    try withDirectory(containing: []) { directory in
      let reference = SnapshotReference(base: "a view", pathExtension: "png", in: directory)

      #expect(reference.name == "a-view.png")
    }
  }

  @Test func `a file naming this platform is preferred to the shared one`() throws {
    let platform = try #require(SnapshotPlatform.name)

    try withDirectory(containing: ["a-view.png", "a-view.\(platform).png"]) { directory in
      let reference = SnapshotReference(base: "a view", pathExtension: "png", in: directory)

      #expect(reference.name == "a-view.\(platform).png")
    }
  }

  @Test func `a file naming this version of this platform is preferred to either`() throws {
    let platform = try #require(SnapshotPlatform.name)
    let versioned = try #require(SnapshotPlatform.versionedName)

    let files = ["a-view.png", "a-view.\(platform).png", "a-view.\(versioned).png"]
    try withDirectory(containing: files) { directory in
      let reference = SnapshotReference(base: "a view", pathExtension: "png", in: directory)

      #expect(reference.name == "a-view.\(versioned).png")
    }
  }

  /// A run reads and writes its own platform's reference and no other, so a file left behind by a
  /// platform this one is not is no more its reference than an unrelated file would be.
  @Test func `a file naming another platform is left to that platform`() throws {
    try withDirectory(containing: ["a-view.zos.png"]) { directory in
      let reference = SnapshotReference(base: "a view", pathExtension: "png", in: directory)

      #expect(reference.name == "a-view.png")
    }
  }

  /// The platform is not read off a name but appended to one, so a qualifier keeps its place even
  /// where it reads like a platform itself.
  @Test func `the platform follows the qualifiers`() throws {
    let platform = try #require(SnapshotPlatform.name)

    try withDirectory(containing: ["a-view.\(platform).\(platform).png"]) { directory in
      let reference = SnapshotReference(
        base: "a view",
        qualifiers: [platform],
        pathExtension: "png",
        in: directory
      )

      #expect(reference.name == "a-view.\(platform).\(platform).png")
    }
  }
}

// MARK: - Private

private let directory = URL(filePath: "/references", directoryHint: .isDirectory)

/// Runs `body` against a scratch directory holding an empty file per name, removed afterwards.
///
/// Only the presence of a file decides which reference a name resolves to, so what is in one does
/// not matter here.
private func withDirectory(containing fileNames: [String], _ body: (URL) throws -> Void) throws {
  let fileManager = FileManager.default
  let directory = fileManager.temporaryDirectory
    .appending(path: "SnapshotReferenceTests-\(UUID().uuidString)", directoryHint: .isDirectory)
  try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
  defer { try? fileManager.removeItem(at: directory) }

  for fileName in fileNames {
    try Data().write(to: directory.appending(path: fileName))
  }
  try body(directory)
}
