#if os(iOS) || os(macOS) || os(tvOS)
import Foundation
import Testing

#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

@testable import Snapshotting

/// Covers `runtimeDescription` directly: what the strategies that record a hierarchy as text get back,
/// and what they get instead of an answer. What each of them then records is covered by `ViewTests`
/// and `ViewControllerTests`.
@MainActor
struct RuntimeDescriptionTests {

  /// The one guarantee the strategies rely on, and the reason they all come through here: no address
  /// survives into a recording.
  @Test func `a view describes itself with no address in it`() throws {
    #if canImport(AppKit)
    let described = try runtimeDescription(of: NSView(), printedBy: "_subtreeDescription")
    #else
    let described = try runtimeDescription(of: UIView(), printedBy: "recursiveDescription")
    #endif

    #expect(described.contains("View"))
    #expect(!described.contains("0x"))
  }

  /// The selectors are private, so an OS is free to stop answering one. Asking anyway would raise an
  /// Objective-C exception and take the whole run down; this is what makes it one snapshot's failure.
  @Test func `an object that does not answer is reported rather than asked`() {
    #expect(throws: RuntimeDescriptionError.selectorUnavailable("recursiveDescription")) {
      try runtimeDescription(of: NSObject(), printedBy: "recursiveDescription")
    }
  }

  /// Nothing about a selector named at runtime says it answers with text — `self` answers with the
  /// object — so the cast that every caller used to make is a failure rather than a crash.
  @Test func `an answer that is not text is reported`() {
    #expect(throws: RuntimeDescriptionError.descriptionNotText("self")) {
      try runtimeDescription(of: NSObject(), printedBy: "self")
    }
  }
}
#endif
