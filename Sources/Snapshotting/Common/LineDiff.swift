import Foundation

/// The characters that prefix a line in a rendered patch.
///
/// Two of them only resemble ASCII: a removed line is marked with U+2212 MINUS SIGN rather than a
/// hyphen, and a shared line with U+2007 FIGURE SPACE rather than a space. The figure space is as
/// wide as a digit, so the lines of a patch align under its `@@` header.
private enum Marker {
  /// Prefixes a line present only in the reference.
  static let removed = "\u{2212}"

  /// Prefixes a line present only in the new value.
  static let added = "+"

  /// Prefixes a line both sides share.
  static let unchanged = "\u{2007}"

  /// Appended to a line ending in a space, so that trailing whitespace is visible in a patch that
  /// would otherwise appear to report two identical lines.
  static let trailingSpace = "¬"
}

/// A run of consecutive lines that both sides share, or that belongs to only one of them.
struct LineRun: Equatable {
  enum Kind {
    /// Lines present only in the reference.
    case removed

    /// Lines present only in the new value.
    case added

    /// Lines both sides share.
    case unchanged
  }

  let lines: [String]
  let kind: Kind
}

/// Splits two sequences of lines into the runs they share and the runs they do not.
///
/// Anchors on the longest run of lines common to both sides and recurses either side of it. A line
/// that merely moved therefore reads as a removal in one place and an addition in another, rather
/// than as a move.
func lineDiff(_ old: [String], _ new: [String]) -> [LineRun] {
  var oldIndices = [String: [Int]]()
  for (offset, line) in old.enumerated() {
    oldIndices[line, default: []].append(offset)
  }

  // The longest run of lines common to both sides, found by walking `new` a line at a time and
  // extending every run that ended on the line before it. `runLengths` maps an index in `old` to the
  // length of the run ending there, so a run grows by looking its own length up one line back.
  var runLengths = [Int: Int]()
  var oldStart = 0
  var newStart = 0
  var length = 0

  for (newIndex, line) in new.enumerated() {
    var extended = [Int: Int]()
    // Compared against the longest run found *before* this line, not against one updated as the
    // line is walked, so the last of several equally long runs wins. Either is a valid anchor, but
    // they produce different patches, and this is the one the reference output was recorded with.
    let longestBefore = length

    for oldIndex in oldIndices[line] ?? [] {
      let runLength = (runLengths[oldIndex - 1] ?? 0) + 1
      extended[oldIndex] = runLength

      if runLength > longestBefore {
        length = runLength
        oldStart = oldIndex - runLength + 1
        newStart = newIndex - runLength + 1
      }
    }
    runLengths = extended
  }

  guard length > 0 else {
    return (old.isEmpty ? [] : [LineRun(lines: old, kind: .removed)])
      + (new.isEmpty ? [] : [LineRun(lines: new, kind: .added)])
  }
  return lineDiff(Array(old.prefix(upTo: oldStart)), Array(new.prefix(upTo: newStart)))
    + [LineRun(lines: Array(old.suffix(from: oldStart).prefix(length)), kind: .unchanged)]
    + lineDiff(Array(old.suffix(from: oldStart + length)), Array(new.suffix(from: newStart + length)))
}

/// One `@@` section of a patch: a window of lines around one or more changes, together with the
/// range of lines it covers on each side.
struct Hunk {
  let oldStart: Int
  let oldCount: Int
  let newStart: Int
  let newCount: Int

  /// The lines of the window, each already carrying its marker.
  let patchLines: [String]

  /// The `@@ −3,10 +3,10 @@` header, whose ranges are numbered from one.
  var patchMark: String {
    let old = "\(Marker.removed)\(oldStart + 1),\(oldCount)"
    let new = "\(Marker.added)\(newStart + 1),\(newCount)"
    return "@@ \(old) \(new) @@"
  }

  /// Whether the window holds a change rather than context alone. A hunk of pure context is dropped
  /// instead of rendered, which is what keeps unchanged stretches out of a patch.
  var hasChanges: Bool {
    patchLines.contains { $0.hasPrefix(Marker.removed) || $0.hasPrefix(Marker.added) }
  }

  init(
    oldStart: Int = 0,
    oldCount: Int = 0,
    newStart: Int = 0,
    newCount: Int = 0,
    patchLines: [String] = []
  ) {
    self.oldStart = oldStart
    self.oldCount = oldCount
    self.newStart = newStart
    self.newCount = newCount
    self.patchLines = patchLines
  }

  /// A hunk covering the same range on both sides, as any run of shared lines does.
  init(start: Int = 0, count: Int = 0, patchLines: [String] = []) {
    self.init(
      oldStart: start,
      oldCount: count,
      newStart: start,
      newCount: count,
      patchLines: patchLines
    )
  }

  /// Extends a hunk with a following one.
  ///
  /// The right operand's starts are read as offsets *relative* to the left operand, which is why
  /// they are summed rather than replaced: a hunk under construction begins at zero and is pushed
  /// forward by each run appended to it.
  static func + (lhs: Hunk, rhs: Hunk) -> Hunk {
    Hunk(
      oldStart: lhs.oldStart + rhs.oldStart,
      oldCount: lhs.oldCount + rhs.oldCount,
      newStart: lhs.newStart + rhs.newStart,
      newCount: lhs.newCount + rhs.newCount,
      patchLines: lhs.patchLines + rhs.patchLines
    )
  }
}

/// Groups line runs into the hunks of a patch, keeping at most `context` shared lines on either side
/// of a change and leaving longer shared stretches out altogether.
func hunks(of runs: [LineRun], context: Int = 4) -> [Hunk] {
  func marked(with marker: String) -> (String) -> String {
    { marker + $0 + ($0.hasSuffix(" ") ? Marker.trailingSpace : "") }
  }

  var completed: [Hunk] = []
  var open = Hunk()

  for run in runs {
    let lineCount = run.lines.count

    switch run.kind {
    case .unchanged where lineCount > context * 2:
      // Long enough to close the open hunk after `context` trailing lines and start a fresh one on
      // the last `context` lines, dropping the stretch between them from the patch.
      let leading = run.lines.prefix(context).map(marked(with: Marker.unchanged))
      let closed = open + Hunk(count: context, patchLines: leading)
      let next = Hunk(
        oldStart: open.oldStart + open.oldCount + lineCount - context,
        oldCount: context,
        newStart: open.newStart + open.newCount + lineCount - context,
        newCount: context,
        patchLines: run.lines.suffix(context).map(marked(with: Marker.unchanged))
      )
      if closed.hasChanges { completed.append(closed) }
      open = next
    case .unchanged where open.patchLines.isEmpty:
      // Leading context, before any change has been seen: keep only the last `context` lines and
      // start the hunk at whichever line that turns out to be.
      let lines = run.lines.suffix(context).map(marked(with: Marker.unchanged))
      open = open + Hunk(start: lineCount - lines.count, count: lines.count, patchLines: lines)
    case .unchanged:
      open = open + Hunk(count: lineCount, patchLines: run.lines.map(marked(with: Marker.unchanged)))
    case .removed:
      open = open + Hunk(oldCount: lineCount, patchLines: run.lines.map(marked(with: Marker.removed)))
    case .added:
      open = open + Hunk(newCount: lineCount, patchLines: run.lines.map(marked(with: Marker.added)))
    }
  }

  if open.hasChanges { completed.append(open) }
  return completed
}
