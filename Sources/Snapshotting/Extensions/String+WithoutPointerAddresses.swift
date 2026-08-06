extension String {
  /// The string with the address of every object in it removed.
  ///
  /// Descriptions that come out of the Objective-C runtime name each object by where it happens to
  /// live, which differs between two runs of the same hierarchy. Recording one verbatim would compare
  /// a new address against an old one every time:
  ///
  /// ```
  /// <UIButton: 0x14b40a3f0; frame = (0 0; 60 30); layer = <CALayer: 0x6000029a41e0>>
  /// <UIButton; frame = (0 0; 60 30); layer = <CALayer>>
  /// ```
  var withoutPointerAddresses: String {
    // The colon or whitespace that introduced an address goes with it, so that nothing is left
    // dangling where it was, while the whitespace behind it is put back, so that removing an address
    // does not run two words together.
    replacing(/:?\s*0x[0-9a-fA-F]+(?<spacing>\s*)/) { $0.spacing }
  }
}
