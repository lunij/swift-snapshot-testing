import Foundation

let osVersion = ProcessInfo.processInfo.operatingSystemVersion

#if os(iOS)
let platform = "ios"
#elseif os(macOS)
let platform = "macos"
#elseif os(tvOS)
let platform = "tvos"
#endif
