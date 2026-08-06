import Testing

@testable import Snapshotting

/// Covers `withoutPointerAddresses` against the shapes the Objective-C runtime actually prints, since
/// every text recording of a view, a view controller or an `NSObject` dump goes through it and would
/// otherwise carry an address that differs between two runs.
struct PointerAddressTests {

  /// UIKit introduces an address with a colon, and the colon has to go with it: a recording reading
  /// `<UIButton:; frame` would be stranger than the address it replaced.
  @Test func `a uikit description keeps the class and loses the colon`() {
    #expect(
      "<UIButton: 0x14b40a3f0; frame = (0 0; 60 30); layer = <CALayer: 0x6000029a41e0>>"
        .withoutPointerAddresses
        == "<UIButton; frame = (0 0; 60 30); layer = <CALayer>>"
    )
  }

  /// AppKit introduces one with a space instead, and there the space has to stay, or the class name
  /// would run into whatever the runtime prints next.
  @Test func `an appkit description keeps the space between class and title`() {
    #expect(
      "[   AF    ! wLU ] h=--- v=--- NSButton 0x14e10c630 \"Push Me\" f=(0,0,76.5,24)"
        .withoutPointerAddresses
        == "[   AF    ! wLU ] h=--- v=--- NSButton \"Push Me\" f=(0,0,76.5,24)"
    )
  }

  @Test func `a controller hierarchy loses an address inside angle brackets`() {
    #expect(
      "<UITabBarController 0x10680c000>, state: appeared, view: <UILayoutContainerView 0x106710e00>"
        .withoutPointerAddresses
        == "<UITabBarController>, state: appeared, view: <UILayoutContainerView>"
    )
  }

  /// Addresses come out lowercase on Apple platforms, so this is about not trusting that: half an
  /// address left behind reads as a value rather than as something that was meant to be removed.
  @Test func `an uppercase address is removed whole`() {
    #expect("<Blob: 0xABCDEF01>".withoutPointerAddresses == "<Blob>")
  }

  /// Every text recording passes through here, most of them naming no object at all, so leaving text
  /// that has no address in it untouched is the common case rather than an edge of one.
  @Test func `a description with no address is left alone`() {
    #expect("Blob(count: 0, name: \"Blobby\")".withoutPointerAddresses == "Blob(count: 0, name: \"Blobby\")")
  }
}
