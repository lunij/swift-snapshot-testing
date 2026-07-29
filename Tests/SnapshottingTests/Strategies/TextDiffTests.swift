import Snapshotting
import Testing

struct TextDiffTests {
  /// The patch prefixes context lines with a figure space (U+2007) and removed lines with a minus
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

  @Test func `matching text produces no failure`() throws {
    #expect(try SnapshotComparator<String>.lines.diff("same", "same") == nil)
  }
}
