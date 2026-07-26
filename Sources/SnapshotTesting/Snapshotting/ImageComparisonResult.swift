#if os(iOS) || os(macOS) || os(tvOS)
import CoreGraphics

enum ImageComparisonResult {
  case cgContextDataConversionFailed
  case cgImageConversionFailed
  case isMatching
  case isNotMatching
  case perceptualComparisonFailed
  case unequalSize(old: CGSize, new: CGSize)
  case unmatchedPrecision(expected: Float, actual: Float)
  case unmatchedPrecisions(
    expectedPixelPrecision: Float,
    actualPixelPrecision: Float,
    expectedPerceptualPrecision: Float,
    actualPerceptualPrecision: Float
  )
}

extension ImageComparisonResult {
  /// Maps a comparison result to a snapshot failure, or `nil` for a match. The artifacts
  /// closure is only invoked for results where a visual diff is meaningful.
  func snapshotFailure(artifacts: () throws -> [SnapshotFailure.Artifact]) throws -> SnapshotFailure? {
    switch self {
    case .isMatching:
      return nil
    case .cgContextDataConversionFailed, .cgImageConversionFailed:
      return SnapshotFailure(reason: "Image could not be compared (Core Graphics failure).")
    case .perceptualComparisonFailed:
      return SnapshotFailure(reason: "Image could not be compared (perceptual comparison failed).")
    case .isNotMatching:
      return SnapshotFailure(
        reason: "Image does not match reference.",
        artifacts: try artifacts()
      )
    case let .unequalSize(oldSize, newSize):
      return SnapshotFailure(
        reason: """
          Image size \(format(newSize)) does not match reference size \(format(oldSize)).
          """,
        artifacts: try artifacts()
      )
    case let .unmatchedPrecision(expectedPrecision, actualPrecision):
      return SnapshotFailure(
        reason: """
          Image does not match reference (pixel precision \(actualPrecision) is less than \
          required \(expectedPrecision)).
          """,
        artifacts: try artifacts()
      )
    case let .unmatchedPrecisions(
      expectedPixelPrecision,
      actualPixelPrecision,
      expectedPerceptualPrecision,
      actualPerceptualPrecision
    ):
      return SnapshotFailure(
        reason: "Image does not match reference (below required perceptual precision).",
        detail: """
          The percentage of pixels that match \(actualPixelPrecision) is less than expected \(expectedPixelPrecision)
          The lowest perceptual color precision \(actualPerceptualPrecision) is less than expected \(expectedPerceptualPrecision)
          """,
        artifacts: try artifacts()
      )
    }
  }
}

private func format(_ size: CGSize) -> String {
  "\(Int(size.width))×\(Int(size.height))"
}
#endif
