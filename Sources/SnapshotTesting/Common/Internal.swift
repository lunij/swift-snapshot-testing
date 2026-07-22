#if os(macOS)
  import Cocoa
  typealias XImage = NSImage
  typealias XImageView = NSImageView
  typealias XView = NSView
#elseif os(iOS) || os(tvOS)
  import UIKit
  typealias XImage = UIImage
  typealias XImageView = UIImageView
  typealias XView = UIView
#endif

// Idempotent teardown token: run() executes the closure at most once.
// Teardowns must only be registered, unregistered, and run on the main thread.
final class SnapshotTeardown {
  private var _run: (() -> Void)?
  init(_ run: @escaping () -> Void) { _run = run }
  func run() { _run?(); _run = nil }
}

// Tracks teardowns that have been set up but not yet cleaned up.
// assertSnapshot drains this on timeout so that window/rootVC/traitOverrides
// from a timed-out async snapshot don't leak into subsequent tests.
enum PendingSnapshotTeardowns {
  private static var pending: [SnapshotTeardown] = []

  static func register(_ teardown: SnapshotTeardown) {
    pending.append(teardown)
  }

  static func unregister(_ teardown: SnapshotTeardown) {
    pending.removeAll(where: { $0 === teardown })
  }

  // Snapshot and clear the list before running so a re-entrant run() is a no-op.
  static func drain() {
    let all = pending
    pending.removeAll()
    all.forEach { $0.run() }
  }
}
