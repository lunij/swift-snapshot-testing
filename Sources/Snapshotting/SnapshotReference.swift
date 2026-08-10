import Foundation

/// The file a snapshot is compared against.
///
/// A reference is named after what the snapshot is of, and then narrowed until it names one file:
///
/// ```
/// <base>.<strategyIdentifier>.<qualifiers…>.<pathExtension>
/// ```
///
/// The strategy's identifier says how the value was rendered. It sits next to the base because two
/// renderings of one value are two references rather than two variants of one, so everything after
/// it qualifies a single rendering. Where the qualifiers go is fixed here; what they mean is left
/// to whoever supplies them, which is the only place it is known.
///
/// ```swift
/// SnapshotReference(
///   base: "a-view-in-both-appearances",
///   strategyIdentifier: "recursive-description",
///   qualifiers: ["dark"],
///   pathExtension: "txt",
///   in: directory
/// )
/// // a-view-in-both-appearances.recursive-description.dark.txt
/// ```
package struct SnapshotReference: Hashable, Sendable {
  /// The file holding the reference snapshot.
  package let url: URL

  /// The name of the reference file, including its path extension.
  package var name: String { url.lastPathComponent }

  /// Composes the reference a snapshot is written to and read from.
  ///
  /// Every component is reduced to what can name a file, and one that has nothing left after that
  /// is dropped rather than left as an empty component. A qualifier a caller cannot supply
  /// therefore costs nothing: `nil` and `""` both name the same file as leaving it out.
  ///
  /// - Parameters:
  ///   - base: What the snapshot is of.
  ///   - strategyIdentifier: The `SnapshotStrategy/identifier` of the strategy that rendered the
  ///     value, which strategies carry only where their path extension leaves the format ambiguous.
  ///   - qualifiers: What tells this snapshot from the others sharing its base, most general first.
  ///   - pathExtension: The path extension of the strategy's format, if any.
  ///   - directory: The directory holding reference snapshots.
  package init(
    base: String,
    strategyIdentifier: String? = nil,
    qualifiers: [String] = [],
    pathExtension: String? = nil,
    in directory: URL
  ) {
    var components = [base]
    if let strategyIdentifier {
      components.append(strategyIdentifier)
    }
    components.append(contentsOf: qualifiers)

    let name =
      components
      .map { $0.sanitizePathComponent() }
      .filter { !$0.isEmpty }
      .joined(separator: ".")

    var url = directory.appending(path: name)
    if let pathExtension {
      url = url.appendingPathExtension(pathExtension)
    }
    self.url = url
  }
}

// MARK: - Private

private extension String {
  /// Reduces a component to what can name a file, turning `"a value, rendered"` into
  /// `"a-value-rendered"`.
  ///
  /// Applying this to a component that has already been through it leaves it alone, so a caller
  /// that sanitizes on its own terms is not undone here.
  func sanitizePathComponent() -> String {
    replacing(/\W+/, with: "-")
      .replacing(/^-|-$/, with: "")
  }
}
