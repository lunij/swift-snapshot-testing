#if os(macOS)
  import Cocoa
  import XCTest

  extension Diffing where Value == NSImage {
    /// A pixel-diffing strategy for NSImage's which requires a 100% match.
    public static let image = Diffing.image()

    /// A pixel-diffing strategy for NSImage that allows customizing how precise the matching must be.
    ///
    /// - Parameters:
    ///   - precision: The percentage of pixels that must match.
    ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a
    ///     match. 98-99% mimics
    ///     [the precision](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e) of the
    ///     human eye.
    /// - Returns: A new diffing strategy.
    public static func image(precision: Float = 1, perceptualPrecision: Float = 1) -> Diffing {
      return .init(
        toData: convertToData,
        fromData: { NSImage(data: $0)! }
      ) { old, new in
        do {
          let result = try compare(old, new, precision: precision, perceptualPrecision: perceptualPrecision)
          switch result {
          case .cgContextDataConversionFailed:
            return ("Core Graphics failure", [])
          case .isMatching:
            return nil
          case .isNotMatching:
            let diff = try diffImage(old, new)
            return ("Snapshot does not match reference", attachments(old, new, diff))
          case .perceptualComparisonFailed:
            return ("Perceptual comparison failed", [])
          case let .unequalSize(oldSize, newSize):
            let diff = try diffImage(old, new)
            return ("Snapshot size \(newSize) is unequal to expected size \(oldSize)", attachments(old, new, diff))
          case let .unmatchedPrecision(expectedPrecision, actualPrecision):
            let diff = try diffImage(old, new)
            return ("Actual image precision \(actualPrecision) is less than expected \(expectedPrecision)", attachments(old, new, diff))
          case let .unmatchedPrecisions(expectedPixelPrecision, actualPixelPrecision, expectedPerceptualPrecision, actualPerceptualPrecision):
            let diff = try diffImage(old, new)
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

  extension Snapshotting where Value == NSImage, Format == NSImage {
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
    public static func image(precision: Float = 1, perceptualPrecision: Float = 1) -> Snapshotting {
      return .init(
        pathExtension: "png",
        diffing: .image(precision: precision, perceptualPrecision: perceptualPrecision)
      )
    }
  }

  private func convertToData(_ image: NSImage) throws -> Data {
    if image.size == .zero {
      throw ImageConversionError.zeroSize
    }
    if image.size.width == 0 {
      throw ImageConversionError.zeroWidth
    }
    if image.size.height == 0 {
      throw ImageConversionError.zeroHeight
    }
    let cgImage = try image.cgImage()
    let rep = NSBitmapImageRep(cgImage: cgImage)
    rep.size = image.size
    guard let data = rep.representation(using: .png, properties: [:]) else {
      throw ImageConversionError.pngDataConversionFailed
    }
    return data
  }

  private func compare(_ old: NSImage, _ new: NSImage, precision: Float, perceptualPrecision: Float) throws -> ImageComparisonResult {
    let oldCgImage = try old.cgImage()
    let newCgImage = try new.cgImage()

    guard oldCgImage.width == newCgImage.width, oldCgImage.height == newCgImage.height else {
      return .unequalSize(old: oldCgImage.size, new: newCgImage.size)
    }
    guard let oldContext = context(for: oldCgImage), let oldData = oldContext.data else {
      return .cgContextDataConversionFailed
    }
    guard let newContext = context(for: newCgImage), let newData = newContext.data else {
      return .cgContextDataConversionFailed
    }
    let byteCount = oldContext.height * oldContext.bytesPerRow
    if memcmp(oldData, newData, byteCount) == 0 {
      return .isMatching
    }
    guard
      let data = try? convertToData(new),
      let newerCgImage = try NSImage(data: data)?.cgImage(),
      let newerContext = context(for: newerCgImage),
      let newerData = newerContext.data
    else {
      return .cgContextDataConversionFailed
    }
    if memcmp(oldData, newerData, byteCount) == 0 {
      return .isMatching
    }
    if precision >= 1, perceptualPrecision >= 1 {
      return .isNotMatching
    }
    if perceptualPrecision < 1, #available(macOS 10.13, *) {
      return perceptuallyCompare(
        CIImage(cgImage: oldCgImage),
        CIImage(cgImage: newCgImage),
        pixelPrecision: precision,
        perceptualPrecision: perceptualPrecision
      )
    } else {
      let oldRep = NSBitmapImageRep(cgImage: oldCgImage).bitmapData!
      let newRep = NSBitmapImageRep(cgImage: newerCgImage).bitmapData!
      let byteCountThreshold = Int((1 - precision) * Float(byteCount))
      var differentByteCount = 0
      // NB: We are purposely using a verbose 'while' loop instead of a 'for in' loop.  When the
      //     compiler doesn't have optimizations enabled, like in test targets, a `while` loop is
      //     significantly faster than a `for` loop for iterating through the elements of a memory
      //     buffer. Details can be found in [SR-6983](https://github.com/apple/swift/issues/49531)
      var index = 0
      while index < byteCount {
        defer { index += 1 }
        if oldRep[index] != newRep[index] {
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

  private func context(for cgImage: CGImage) -> CGContext? {
    guard
      let space = cgImage.colorSpace,
      let context = CGContext(
        data: nil,
        width: cgImage.width,
        height: cgImage.height,
        bitsPerComponent: cgImage.bitsPerComponent,
        bytesPerRow: cgImage.bytesPerRow,
        space: space,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      )
    else { return nil }

    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
    return context
  }

  private func diffImage(_ old: NSImage, _ new: NSImage) throws -> NSImage {
    let oldCiImage = CIImage(cgImage: try old.cgImage())
    let newCiImage = CIImage(cgImage: try new.cgImage())
    let differenceFilter = CIFilter(name: "CIDifferenceBlendMode")!
    differenceFilter.setValue(oldCiImage, forKey: kCIInputImageKey)
    differenceFilter.setValue(newCiImage, forKey: kCIInputBackgroundImageKey)
    let maxSize = CGSize(
      width: max(old.size.width, new.size.width),
      height: max(old.size.height, new.size.height)
    )
    let rep = NSCIImageRep(ciImage: differenceFilter.outputImage!)
    let difference = NSImage(size: maxSize)
    difference.addRepresentation(rep)
    return difference
  }

  private extension NSImage {
    func cgImage() throws -> CGImage {
      guard let cgImage = cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        throw ImageConversionError.cgImageConversionFailed
      }
      return cgImage
    }
  }
#endif
