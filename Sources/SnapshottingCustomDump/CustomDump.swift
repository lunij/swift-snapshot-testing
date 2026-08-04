import CustomDump
import Snapshotting

extension SnapshotStrategy where Format == String {
  /// A snapshot strategy for comparing any structure based on a
  /// [custom dump](https://github.com/pointfreeco/swift-custom-dump).
  ///
  /// Records a structure as:
  ///
  /// ```
  /// User(
  ///   bio: "Blobbed around the world.",
  ///   id: 1,
  ///   name: "Blobby"
  /// )
  /// ```
  public static var customDump: SnapshotStrategy {
    DirectSnapshotStrategy.lines.transform(identifier: "custom-dump", String.init(customDumping:))
  }
}
