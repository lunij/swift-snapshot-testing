import Foundation
import Snapshotting
import Testing

/// Covers what the `lines` comparator makes of a patch: the failure it packages one into, and how it
/// splits a string into the lines it compares. The runs and hunks the patch is built from are
/// covered by `LineDiffTests`.
struct LinesComparatorTests {
  @Test func `matching text produces no failure`() throws {
    #expect(try SnapshotComparator<String>.lines.diff("same", "same") == nil)
  }

  /// The patch prefixes shared lines with a figure space (U+2007) and removed lines with a minus
  /// sign (U+2212), neither of which is the ASCII character it resembles. Written as escapes here
  /// because they are indistinguishable from a space and a hyphen in source.
  @Test func `a text mismatch is reported as a patch`() throws {
    let failure = try SnapshotComparator<String>.lines.diff(
      """
      first
      second
      third
      """,
      """
      first
      changed
      third
      """
    )

    #expect(failure?.reason == "Text does not match reference (+1 \u{2212}1 lines).")
    #expect(
      failure?.detail == """
        @@ \u{2212}1,3 +1,3 @@
        \u{2007}first
        \u{2212}second
        +changed
        \u{2007}third
        """
    )
  }

  @Test func `the reason counts the lines added and removed`() throws {
    let added = try SnapshotComparator<String>.lines.diff("a\nb", "a\nx\nb")
    let removed = try SnapshotComparator<String>.lines.diff("a\nx\nb", "a\nb")

    #expect(added?.reason == "Text does not match reference (+1 \u{2212}0 lines).")
    #expect(removed?.reason == "Text does not match reference (+0 \u{2212}1 lines).")
  }

  /// Splitting keeps empty subsequences, so an empty string is one blank line rather than no lines
  /// at all. Both counts are therefore one higher than the visible content suggests.
  @Test func `an empty string is one blank line`() throws {
    let emptied = try SnapshotComparator<String>.lines.diff("a\nb", "")
    let unwritten = try SnapshotComparator<String>.lines.diff("", "a\nb")

    #expect(emptied?.reason == "Text does not match reference (+1 \u{2212}2 lines).")
    #expect(unwritten?.reason == "Text does not match reference (+2 \u{2212}1 lines).")
  }

  @Test func `a trailing newline is a trailing blank line`() throws {
    let failure = try SnapshotComparator<String>.lines.diff("a", "a\n")

    #expect(failure?.reason == "Text does not match reference (+1 \u{2212}0 lines).")
    #expect(
      failure?.detail == """
        @@ \u{2212}1,1 +1,2 @@
        \u{2007}a
        +
        """
    )
  }

  @Test func `the patch is returned as an artifact`() throws {
    let failure = try SnapshotComparator<String>.lines.diff("a\nb", "a\nc")

    #expect(failure?.artifacts.map(\.name) == ["difference.patch"])
    #expect(failure?.artifacts.first?.data == Data((failure?.detail ?? "").utf8))
  }
}
