import Foundation
import Snapshotting
import Testing

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

// Covers which strategies describe themselves. A strategy carries an identifier only where its path
// extension leaves its format ambiguous, so the two properties are asserted together — a `nil`
// identifier is a claim about the extension standing on its own, not an omission.
struct StrategyIdentifierTests {
  @Test func `a text format that has a sibling identifies itself`() {
    #expect(SnapshotStrategy<Int, String>.description.identifier == "description")
    #expect(SnapshotStrategy<Int, String>.description.pathExtension == "txt")

    #expect(SnapshotStrategy<Int, String>.dump.identifier == "dump")
    #expect(SnapshotStrategy<Int, String>.dump.pathExtension == "txt")
  }

  @Test func `a format that speaks for itself carries no identifier`() {
    #expect(DirectSnapshotStrategy<String>.lines.identifier == nil)
    #expect(DirectSnapshotStrategy<String>.lines.pathExtension == "txt")

    #expect(SnapshotStrategy<Any, String>.json.identifier == nil)
    #expect(SnapshotStrategy<Any, String>.json.pathExtension == "json")

    #expect(DirectSnapshotStrategy<Data>.data.identifier == nil)
    #expect(DirectSnapshotStrategy<Data>.data.pathExtension == nil)
  }

  @Test func `an encoded structure is identified by its encoding`() {
    struct User: Encodable { let id: Int }
    #expect(SnapshotStrategy<User, String>.json.identifier == nil)
    #expect(SnapshotStrategy<User, String>.json.pathExtension == "json")
    #expect(SnapshotStrategy<User, String>.plist.identifier == nil)
    #expect(SnapshotStrategy<User, String>.plist.pathExtension == "plist")
  }

  #if !os(WASI)
  @Test func `the two request renderings identify themselves`() {
    #expect(SnapshotStrategy<URLRequest, String>.curl.identifier == "curl")
    #expect(SnapshotStrategy<URLRequest, String>.curl.pathExtension == "txt")

    #expect(SnapshotStrategy<URLRequest, String>.raw.identifier == "raw")
    #expect(SnapshotStrategy<URLRequest, String>.raw.pathExtension == "txt")
  }
  #endif

  @Test func `waiting preserves the identifier of the strategy it wraps`() {
    let waited = SnapshotStrategy.wait(for: 0, on: SnapshotStrategy<Int, String>.dump)
    #expect(waited.identifier == "dump")
    #expect(waited.pathExtension == "txt")
  }

  #if os(macOS) || os(iOS) || os(tvOS)
  @Test func `a path describes its elements`() {
    #expect(SnapshotStrategy<CGPath, String>.elementsDescription.identifier == "elements-description")
  }
  #endif

  #if canImport(AppKit)
  @Test func `an AppKit hierarchy describes itself, an image does not`() {
    #expect(SnapshotStrategy<NSView, String>.recursiveDescription.identifier == "recursive-description")
    #expect(SnapshotStrategy<NSViewController, String>.recursiveDescription.identifier == "recursive-description")
    #expect(SnapshotStrategy<NSBezierPath, String>.elementsDescription.identifier == "elements-description")

    #expect(SnapshotStrategy<NSView, NSImage>.image.identifier == nil)
    #expect(SnapshotStrategy<NSView, NSImage>.image.pathExtension == "png")
  }
  #endif

  #if os(iOS) || os(tvOS)
  @Test func `a UIKit hierarchy describes itself, an image does not`() {
    #expect(SnapshotStrategy<UIView, String>.recursiveDescription.identifier == "recursive-description")
    #expect(SnapshotStrategy<UIViewController, String>.recursiveDescription.identifier == "recursive-description")
    #expect(SnapshotStrategy<UIViewController, String>.hierarchy.identifier == "hierarchy")
    #expect(SnapshotStrategy<UIBezierPath, String>.elementsDescription.identifier == "elements-description")

    #expect(SnapshotStrategy<UIView, UIImage>.image.identifier == nil)
    #expect(SnapshotStrategy<UIView, UIImage>.image.pathExtension == "png")
  }
  #endif
}
