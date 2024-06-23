#if os(iOS) || os(tvOS)
  import UIKit
  import XCTest

  extension Diffing where Value == UIImage {
    /// A pixel-diffing strategy for UIImage's which requires a 100% match.
    public static let image = Diffing.image()

    /// A pixel-diffing strategy for UIImage that allows customizing how precise the matching must be.
    ///
    /// - Parameters:
    ///   - precision: The percentage of pixels that must match.
    ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a
    ///     match. 98-99% mimics
    ///     [the precision](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e) of the
    ///     human eye.
    ///   - scale: Scale to use when loading the reference image from disk. If `nil` or the
    ///     `UITraitCollection`s default value of `0.0`, the screens scale is used.
    /// - Returns: A new diffing strategy.
    public static func image(
      precision: Float = 1, perceptualPrecision: Float = 1, scale: CGFloat = 1
    ) -> Diffing {
      Diffing(
        toData: convertToData,
        fromData: { try $0.image(scale: scale) }
      ) { old, new in
        do {
          let result = try compare(old, new, precision: precision, perceptualPrecision: perceptualPrecision)
          switch result {
          case .cgContextDataConversionFailed:
            return ("Core Graphics failure", [])
          case .isMatching:
            return nil
          case .isNotMatching:
            let diff = diffImage(old, new)
            return ("Snapshot does not match reference", attachments(old, new, diff))
          case .perceptualComparisonFailed:
            return ("Perceptual comparison failed", [])
          case let .unequalSize(oldSize, newSize):
            let diff = diffImage(old, new)
            return ("Snapshot size \(newSize) is unequal to expected size \(oldSize)", attachments(old, new, diff))
          case let .unmatchedPrecision(expectedPrecision, actualPrecision):
            let diff = diffImage(old, new)
            return ("Actual image precision \(actualPrecision) is less than expected \(expectedPrecision)", attachments(old, new, diff))
          case let .unmatchedPrecisions(expectedPixelPrecision, actualPixelPrecision, expectedPerceptualPrecision, actualPerceptualPrecision):
            let diff = diffImage(old, new)
            return (
              """
              The percentage of pixels that match \(actualPixelPrecision) is less than expected \(expectedPixelPrecision)
              The lowest perceptual color precision \(actualPerceptualPrecision) is less than expected \(expectedPerceptualPrecision)
              """,
              attachments(old, new, diff)
            )
          }
        } catch {
          return (error.localizedDescription, [])
        }
      }
    }
  }

  extension Snapshotting where Value == UIImage, Format == UIImage {
    /// A snapshot strategy for comparing images based on pixel equality.
    public static var image: Snapshotting {
      return .image()
    }

    /// A snapshot strategy for comparing images based on pixel equality.
    ///
    /// - Parameters:
    ///   - precision: The percentage of pixels that must match.
    ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a
    ///     match. 98-99% mimics
    ///     [the precision](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e) of the
    ///     human eye.
    ///   - scale: The scale of the reference image stored on disk.
    public static func image(
      precision: Float = 1, perceptualPrecision: Float = 1, scale: CGFloat = 1
    ) -> Snapshotting {
      return .init(
        pathExtension: "png",
        diffing: .image(
          precision: precision, perceptualPrecision: perceptualPrecision, scale: scale)
      )
    }
  }

  // remap snapshot & reference to same colorspace
  private let imageContextColorSpace = CGColorSpace(name: CGColorSpace.sRGB)
  private let imageContextBitsPerComponent = 8
  private let imageContextBytesPerPixel = 4

  private func convertToData(_ image: UIImage) throws -> Data {
    if image.size == .zero {
      throw ImageConversionError.zeroSize
    }
    if image.size.width == 0 {
      throw ImageConversionError.zeroWidth
    }
    if image.size.height == 0 {
      throw ImageConversionError.zeroHeight
    }
    guard let data = image.pngData() else {
      throw ImageConversionError.pngDataConversionFailed
    }
    return data
  }

  private func compare(_ old: UIImage, _ new: UIImage, precision: Float, perceptualPrecision: Float) throws -> ImageComparisonResult {
    let oldCgImage = try old.cgImage()
    let newCgImage = try new.cgImage()
    guard oldCgImage.width == newCgImage.width, oldCgImage.height == newCgImage.height else {
      return .unequalSize(old: oldCgImage.size, new: newCgImage.size)
    }
    let pixelCount = oldCgImage.width * oldCgImage.height
    let byteCount = imageContextBytesPerPixel * pixelCount
    var oldBytes = [UInt8](repeating: 0, count: byteCount)
    guard let oldData = context(for: oldCgImage, data: &oldBytes)?.data else {
      return .cgContextDataConversionFailed
    }
    if let newContext = context(for: newCgImage), let newData = newContext.data {
      if memcmp(oldData, newData, byteCount) == 0 {
        return .isMatching
      }
    }
    var newerBytes = [UInt8](repeating: 0, count: byteCount)
    guard
      let pngData = new.pngData(),
      let newerCgImage = UIImage(data: pngData)?.cgImage,
      let newerData = context(for: newerCgImage, data: &newerBytes)?.data
    else {
      return .cgContextDataConversionFailed
    }
    if memcmp(oldData, newerData, byteCount) == 0 {
      return .isMatching
    }
    if precision >= 1, perceptualPrecision >= 1 {
      return .isNotMatching
    }
    if perceptualPrecision < 1, #available(iOS 11.0, tvOS 11.0, *) {
      return perceptuallyCompare(
        CIImage(cgImage: oldCgImage),
        CIImage(cgImage: newCgImage),
        pixelPrecision: precision,
        perceptualPrecision: perceptualPrecision
      )
    } else {
      let byteCountThreshold = Int((1 - precision) * Float(byteCount))
      var differentByteCount = 0
      // NB: We are purposely using a verbose 'while' loop instead of a 'for in' loop.  When the
      //     compiler doesn't have optimizations enabled, like in test targets, a `while` loop is
      //     significantly faster than a `for` loop for iterating through the elements of a memory
      //     buffer. Details can be found in [SR-6983](https://github.com/apple/swift/issues/49531)
      var index = 0
      while index < byteCount {
        defer { index += 1 }
        if oldBytes[index] != newerBytes[index] {
          differentByteCount += 1
        }
      }
      if differentByteCount > byteCountThreshold {
        let actualPrecision = 1 - Float(differentByteCount) / Float(byteCount)
        return .unmatchedPrecision(expected: precision, actual: actualPrecision)
      }
    }
    return .isMatching
  }

  private func context(for cgImage: CGImage, data: UnsafeMutableRawPointer? = nil) -> CGContext? {
    let bytesPerRow = cgImage.width * imageContextBytesPerPixel
    guard
      let colorSpace = imageContextColorSpace,
      let context = CGContext(
        data: data,
        width: cgImage.width,
        height: cgImage.height,
        bitsPerComponent: imageContextBitsPerComponent,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      )
    else { return nil }

    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
    return context
  }

  private func diffImage(_ old: UIImage, _ new: UIImage) -> UIImage {
    let width = max(old.size.width, new.size.width)
    let height = max(old.size.height, new.size.height)
    let scale = max(old.scale, new.scale)
    UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), true, scale)
    new.draw(at: .zero)
    old.draw(at: .zero, blendMode: .difference, alpha: 1)
    let differenceImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    return differenceImage
  }

  private extension UIImage {
    func cgImage() throws -> CGImage {
      guard let cgImage = cgImage else {
        throw ImageConversionError.cgImageConversionFailed
      }
      return cgImage
    }
  }
#endif
