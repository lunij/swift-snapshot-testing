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
///
/// ## Platforms
///
/// That name is then looked for at three rungs, most specific first:
///
/// ```
/// a-view.macos26.png
/// a-view.macos.png
/// a-view.png
/// ```
///
/// The most specific rung that exists wins, and a name with no file yet resolves to the last. So
/// output that every platform renders alike keeps one shared reference indefinitely, while a value
/// that renders differently per platform is split apart by moving the file once — no call site says
/// which of the two it is.
///
/// Nothing parses a file name to find the rung it is on: the candidates are composed here and looked
/// for, so a qualifier that happens to read like a platform is never mistaken for one. And which rung
/// is in use depends only on what is on disk, never on when the reference was composed, so a name
/// resolves the same on a recording run as on a verifying one.
package struct SnapshotReference: Hashable, Sendable {
  /// The file holding the reference snapshot.
  package let url: URL

  /// The name of the reference file, including its path extension.
  package var name: String { url.lastPathComponent }

  /// Composes the reference a snapshot is written to and read from, and resolves which platform it
  /// belongs to by what is on disk.
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

    let stem =
      components
      .map { $0.sanitizePathComponent() }
      .filter { !$0.isEmpty }
      .joined(separator: ".")

    func url(qualifiedBy platform: String? = nil) -> URL {
      var url = directory.appending(path: platform.map { "\(stem).\($0)" } ?? stem)
      if let pathExtension {
        url = url.appendingPathExtension(pathExtension)
      }
      return url
    }

    let fileManager = FileManager.default
    self.url =
      [SnapshotPlatform.versionedName, SnapshotPlatform.name]
      .compactMap { $0.map { url(qualifiedBy: $0) } }
      .first { fileManager.fileExists(atPath: $0.path) }
      ?? url()
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
