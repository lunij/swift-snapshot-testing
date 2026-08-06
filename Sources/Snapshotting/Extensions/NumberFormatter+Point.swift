#if os(iOS) || os(macOS) || os(tvOS)
import CoreGraphics
import Foundation

extension NumberFormatter {
  /// The point written as `(x, y)`, both coordinates formatted by this formatter.
  ///
  /// - Throws: ``PathDescriptionError/coordinateNotFormattable(_:)`` when the formatter will not
  ///   describe a coordinate. A description that recorded some of its coordinates in one format and
  ///   the rest in another would compare against a reference no run could reproduce, so a coordinate
  ///   the formatter declines is a failure rather than something to fall back from.
  func string(from point: CGPoint) throws -> String {
    "(\(try string(from: point.x)), \(try string(from: point.y)))"
  }

  private func string(from coordinate: CGFloat) throws -> String {
    guard let string = string(from: coordinate as NSNumber) else {
      throw PathDescriptionError.coordinateNotFormattable(coordinate)
    }
    return string
  }
}
#endif
