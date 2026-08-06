#if os(iOS) || os(macOS) || os(tvOS)
import Foundation

/// Reads the description an object prints for itself through a selector UIKit and AppKit keep to
/// themselves, with pointer addresses removed so that two runs of one hierarchy record the same text.
///
/// The selectors are named rather than called, because Swift cannot see them: `recursiveDescription`,
/// `_subtreeDescription` and `_printHierarchy` are declared in no header. What comes back is an
/// `NSString`, which is why the cast is here rather than at each place that asks.
///
/// - Throws: ``RuntimeDescriptionError/selectorUnavailable(_:)`` when the object does not implement
///   the selector, which is what an OS that stops printing a hierarchy looks like. Asking anyway
///   would raise an Objective-C exception and take the test run down with it, rather than failing the
///   one snapshot that wanted an answer.
func runtimeDescription(of object: NSObject, printedBy name: String) throws -> String {
  let selector = NSSelectorFromString(name)
  guard object.responds(to: selector), let printed = object.perform(selector) else {
    throw RuntimeDescriptionError.selectorUnavailable(name)
  }
  // The description comes back unretained and autoreleased. Retaining it and then taking that retain
  // back keeps it alive across the bridge to `String` without leaving the retain behind.
  guard let description = printed.retain().takeRetainedValue() as? String else {
    throw RuntimeDescriptionError.descriptionNotText(name)
  }
  return description.withoutPointerAddresses
}
#endif
