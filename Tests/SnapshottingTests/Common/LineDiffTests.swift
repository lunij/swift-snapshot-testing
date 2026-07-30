import Foundation
import Testing

@testable import Snapshotting

/// Covers `lineDiff` and `hunks` directly: which runs two sides of a comparison split into, and how
/// those runs are windowed into the hunks of a patch. What the `lines` comparator renders out of
/// them is covered by `LinesComparatorTests`.
struct LineDiffTests {

  // MARK: - Runs

  @Test func `identical lines are a single unchanged run`() {
    #expect(lineDiff(["a", "b"], ["a", "b"]) == [LineRun(lines: ["a", "b"], kind: .unchanged)])
  }

  @Test func `an inserted line is its own added run`() {
    #expect(
      lineDiff(["a", "b"], ["a", "x", "b"]) == [
        LineRun(lines: ["a"], kind: .unchanged),
        LineRun(lines: ["x"], kind: .added),
        LineRun(lines: ["b"], kind: .unchanged)
      ]
    )
  }

  @Test func `a deleted line is its own removed run`() {
    #expect(
      lineDiff(["a", "x", "b"], ["a", "b"]) == [
        LineRun(lines: ["a"], kind: .unchanged),
        LineRun(lines: ["x"], kind: .removed),
        LineRun(lines: ["b"], kind: .unchanged)
      ]
    )
  }

  /// The removed run comes first, which is what puts a changed line's old text above its new text
  /// once the runs are rendered.
  @Test func `sides with nothing in common are one removed run then one added run`() {
    #expect(
      lineDiff(["a", "b"], ["x", "y"]) == [
        LineRun(lines: ["a", "b"], kind: .removed),
        LineRun(lines: ["x", "y"], kind: .added)
      ]
    )
  }

  @Test func `an empty side produces a single run`() {
    #expect(lineDiff(["a", "b"], []) == [LineRun(lines: ["a", "b"], kind: .removed)])
    #expect(lineDiff([], ["a", "b"]) == [LineRun(lines: ["a", "b"], kind: .added)])
    #expect(lineDiff([], []).isEmpty)
  }

  /// Anchoring on the longest shared run means a line that only moved is not recognised as moved: it
  /// is removed from where it was and added where it now is.
  @Test func `a moved line is a removal and an addition around the run that stayed`() {
    #expect(
      lineDiff(["a", "b", "c"], ["c", "a", "b"]) == [
        LineRun(lines: ["c"], kind: .added),
        LineRun(lines: ["a", "b"], kind: .unchanged),
        LineRun(lines: ["c"], kind: .removed)
      ]
    )
  }

  /// Either `a` is an equally long anchor and either choice describes the edit correctly, but they
  /// split the runs differently. The last one wins: anchoring on the first would instead report `a`
  /// as shared and `b`, `a` as removed.
  @Test func `the last of several equally long shared runs is the anchor`() {
    #expect(
      lineDiff(["a", "b", "a"], ["a"]) == [
        LineRun(lines: ["a", "b"], kind: .removed),
        LineRun(lines: ["a"], kind: .unchanged)
      ]
    )
  }

  // MARK: - Hunks

  @Test func `runs without a change produce no hunk`() {
    #expect(hunks(of: [LineRun(lines: ["a", "b"], kind: .unchanged)]).isEmpty)
    #expect(hunks(of: []).isEmpty)
  }

  @Test func `a hunk covers the range its lines span on each side`() throws {
    let hunk = try #require(hunks(of: lineDiff(["a", "x", "b"], ["a", "b"])).first)

    #expect(hunk.oldStart == 0)
    #expect(hunk.oldCount == 3)
    #expect(hunk.newStart == 0)
    #expect(hunk.newCount == 2)
    #expect(readable(hunk.patchMark) == "@@ -1,3 +1,2 @@")
  }

  /// The markers are spelled out here rather than passed through `readable`, so this is the test that
  /// would catch an ASCII lookalike creeping in.
  @Test func `markers are not the ASCII characters they resemble`() throws {
    let hunk = try #require(
      hunks(
        of: [
          LineRun(lines: ["kept"], kind: .unchanged),
          LineRun(lines: ["gone"], kind: .removed),
          LineRun(lines: ["new"], kind: .added)
        ]
      ).first
    )

    #expect(hunk.patchMark == "@@ \u{2212}1,2 +1,2 @@")
    #expect(hunk.patchLines == ["\u{2007}kept", "\u{2212}gone", "+new"])
  }

  /// A line ending in a space gets a trailing `¬`, so a whitespace-only difference is visible in a
  /// patch that would otherwise appear to report two identical lines.
  @Test func `a line ending in a space is flagged`() {
    let runs = [
      LineRun(lines: ["a "], kind: .removed),
      LineRun(lines: ["a"], kind: .added),
      LineRun(lines: ["b"], kind: .unchanged)
    ]

    #expect(readable(hunks(of: runs)) == ["@@ -1,2 +1,2 @@", "-a ¬", "+a", "·b"])
  }

  @Test func `a shared line ending in a space is flagged too`() {
    let runs = [
      LineRun(lines: ["keep "], kind: .unchanged),
      LineRun(lines: ["old"], kind: .removed),
      LineRun(lines: ["new"], kind: .added)
    ]

    #expect(readable(hunks(of: runs)) == ["@@ -1,2 +1,2 @@", "·keep ¬", "-old", "+new"])
  }

  /// Leading context is capped at four lines. The tail is not: capping it would take a shared run
  /// long enough to split into two hunks, so a run of eight or fewer trailing lines is kept whole.
  @Test func `context is capped before a change but a short tail is kept whole`() {
    let runs = [
      LineRun(lines: (1...6).map { "line\($0)" }, kind: .unchanged),
      LineRun(lines: ["line7"], kind: .removed),
      LineRun(lines: ["CHANGED"], kind: .added),
      LineRun(lines: (8...12).map { "line\($0)" }, kind: .unchanged)
    ]

    #expect(
      readable(hunks(of: runs)) == [
        "@@ -3,10 +3,10 @@",
        "·line3",
        "·line4",
        "·line5",
        "·line6",
        "-line7",
        "+CHANGED",
        "·line8",
        "·line9",
        "·line10",
        "·line11",
        "·line12"
      ]
    )
  }

  /// More than eight shared lines between two changes is enough to close the open hunk and start a
  /// new one, leaving the lines in between out of the patch.
  @Test func `a long shared run splits one hunk into two`() {
    let runs = [
      LineRun(lines: ["line1"], kind: .unchanged),
      LineRun(lines: ["line2"], kind: .removed),
      LineRun(lines: ["EARLY"], kind: .added),
      LineRun(lines: (3...17).map { "line\($0)" }, kind: .unchanged),
      LineRun(lines: ["line18"], kind: .removed),
      LineRun(lines: ["LATE"], kind: .added),
      LineRun(lines: ["line19", "line20"], kind: .unchanged)
    ]

    #expect(hunks(of: runs).count == 2)
    #expect(
      readable(hunks(of: runs)) == [
        "@@ -1,6 +1,6 @@",
        "·line1",
        "-line2",
        "+EARLY",
        "·line3",
        "·line4",
        "·line5",
        "·line6",
        "@@ -14,7 +14,7 @@",
        "·line14",
        "·line15",
        "·line16",
        "·line17",
        "-line18",
        "+LATE",
        "·line19",
        "·line20"
      ]
    )
  }

  @Test func `a short shared run keeps both changes in one hunk`() {
    let runs = [
      LineRun(lines: ["line1"], kind: .unchanged),
      LineRun(lines: ["line2"], kind: .removed),
      LineRun(lines: ["A"], kind: .added),
      LineRun(lines: ["line3", "line4"], kind: .unchanged),
      LineRun(lines: ["line5"], kind: .removed),
      LineRun(lines: ["B"], kind: .added),
      LineRun(lines: (6...12).map { "line\($0)" }, kind: .unchanged)
    ]

    #expect(hunks(of: runs).count == 1)
    #expect(readable(hunks(of: runs)).first == "@@ -1,12 +1,12 @@")
  }

  /// The hunk starts at the first line it actually shows, which is line two here — there are only
  /// five lines of leading context to be had, not the four-line cap plus a first line.
  @Test func `context before the first change is capped to what exists`() {
    let runs = [
      LineRun(lines: ["a", "b", "c", "d", "e"], kind: .unchanged),
      LineRun(lines: ["OLD"], kind: .removed),
      LineRun(lines: ["NEW"], kind: .added)
    ]

    #expect(
      readable(hunks(of: runs)) == ["@@ -2,5 +2,5 @@", "·b", "·c", "·d", "·e", "-OLD", "+NEW"]
    )
  }
}

/// Hunks rendered the way the `lines` comparator renders them — each patch mark followed by its own
/// lines — with the invisible markers swapped for visible stand-ins, so the expectations above read
/// the way they look: `·` for the figure space that prefixes a shared line, `-` for the minus sign
/// that prefixes a removed one.
private func readable(_ hunks: [Hunk]) -> [String] {
  hunks.flatMap { [$0.patchMark] + $0.patchLines }.map(readable)
}

private func readable(_ line: String) -> String {
  line
    .replacingOccurrences(of: "\u{2007}", with: "·")
    .replacingOccurrences(of: "\u{2212}", with: "-")
}
