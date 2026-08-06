import Foundation

/// The platform a run is on, as a component of a reference file's name.
///
/// Mirrors what the test wrapper derives, because this target links only the engine — which takes
/// URLs and names nothing.
enum SnapshotPlatform {
  /// The platform, or `nil` on a platform with no name of its own — where every platform then shares
  /// one reference.
  static let name: String? = {
    #if targetEnvironment(macCatalyst)
    return "catalyst"
    #elseif os(iOS)
    return "ios"
    #elseif os(macOS)
    return "macos"
    #elseif os(tvOS)
    return "tvos"
    #elseif os(watchOS)
    return "watchos"
    #elseif os(visionOS)
    return "visionos"
    #elseif os(Linux)
    return "linux"
    #else
    return nil
    #endif
  }()

  /// The platform and its major version, for output that changes between releases of one platform.
  static let versionedName: String? = name.map {
    "\($0)\(ProcessInfo.processInfo.operatingSystemVersion.majorVersion)"
  }
}
