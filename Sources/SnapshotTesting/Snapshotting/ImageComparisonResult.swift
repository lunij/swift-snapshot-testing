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
#endif
