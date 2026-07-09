#if os(iOS) || os(tvOS)
  import Accelerate.vImage
  import UIKit

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
      precision: Float = 1, perceptualPrecision: Float = 1, scale: CGFloat? = nil
    ) -> Diffing {
      let imageScale: CGFloat
      if let scale = scale, scale != 0.0 {
        imageScale = scale
      } else {
        imageScale = UIScreen.main.scale
      }
      return .diff(
        toData: convertToData,
        fromData: { UIImage(data: $0, scale: imageScale)! }
      ) { old, new in
        func attachments(_ old: XImage, _ new: XImage) throws -> [DiffAttachment] {
          try self.attachments(old, new, diffImage, convertToData)
        }
        let result = compare(old, new, precision: precision, perceptualPrecision: perceptualPrecision)
        switch result {
        case .cgContextDataConversionFailed, .cgImageConversionFailed:
          return ("Core Graphics failure", [])
        case .isMatching:
          return nil
        case .isNotMatching:
          return ("Snapshot does not match reference", try attachments(old, new))
        case .perceptualComparisonFailed:
          return ("Perceptual comparison failed", [])
        case let .unequalSize(oldSize, newSize):
          return ("Snapshot size \(newSize) is unequal to expected size \(oldSize)", try attachments(old, new))
        case let .unmatchedPrecision(expectedPrecision, actualPrecision):
          return ("Actual image precision \(actualPrecision) is less than expected \(expectedPrecision)", try attachments(old, new))
        case let .unmatchedPrecisions(expectedPixelPrecision, actualPixelPrecision, expectedPerceptualPrecision, actualPerceptualPrecision):
          return (
            """
            The percentage of pixels that match \(actualPixelPrecision) is less than expected \(expectedPixelPrecision)
            The lowest perceptual color precision \(actualPerceptualPrecision) is less than expected \(expectedPerceptualPrecision)
            """,
            try attachments(old, new)
          )
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
      precision: Float = 1, perceptualPrecision: Float = 1, scale: CGFloat? = nil
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

  private func compare(_ old: UIImage, _ new: UIImage, precision: Float, perceptualPrecision: Float) -> ImageComparisonResult {
    guard let oldCgImage = old.cgImage, let newCgImage = new.cgImage else {
      return .cgImageConversionFailed
    }
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
    normalizedComponentDiff(old, new)
    ?? blendModeDiff(old, new)
  }

  private func blendModeDiff(_ old: UIImage, _ new: UIImage) -> UIImage {
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

private func normalizedComponentDiff(_ old: UIImage, _ new: UIImage) -> UIImage? {
  guard let oldCgImage = old.cgImage,
        let pngData = new.pngData(),
        let newCgImage = UIImage(data: pngData)?.cgImage,
        oldCgImage.width == newCgImage.width,
        oldCgImage.height == newCgImage.height,
        let oldData = oldCgImage.dataProvider?.data,
        let newData = newCgImage.dataProvider?.data
  else {
    return nil
  }
  
  guard let outputColorSpace = CGColorSpace(name: CGColorSpace.linearGray),
        let outputFormat = vImage_CGImageFormat(
          bitsPerComponent: imageContextBitsPerComponent,
          bitsPerPixel: imageContextBitsPerComponent,
          colorSpace: outputColorSpace,
          bitmapInfo: .init()
        )
  else {
    return nil
  }
  
  let width = oldCgImage.width
  let height = oldCgImage.height
  let pixelCount = width * height
  let scale = old.scale
  
  let oldBytes = CFDataGetBytePtr(oldData)!
  let newBytes = CFDataGetBytePtr(newData)!
  var diffBytes = [UInt8](repeating: 0, count: pixelCount)
  
  var index = 0
  while index < pixelCount {
    defer { index += 1 }
    let pixelOffset = index * imageContextBytesPerPixel
    
    let rOld = Int16(oldBytes[pixelOffset])
    let gOld = Int16(oldBytes[pixelOffset + 1])
    let bOld = Int16(oldBytes[pixelOffset + 2])
    let aOld = Int16(oldBytes[pixelOffset + 3])
    
    let rNew = Int16(newBytes[pixelOffset])
    let gNew = Int16(newBytes[pixelOffset + 1])
    let bNew = Int16(newBytes[pixelOffset + 2])
    let aNew = Int16(newBytes[pixelOffset + 3])
    
    let rDiff = abs(rOld - rNew)
    let gDiff = abs(gOld - gNew)
    let bDiff = abs(bOld - bNew)
    let aDiff = abs(aOld - aNew)
    
    let maxDiff = max(rDiff, gDiff, bDiff, aDiff)
    diffBytes[index] = UInt8(maxDiff)
  }
  
  let outputCgImage: CGImage? = diffBytes.withUnsafeMutableBytes { diffPtr in
    var diffBuffer = vImage_Buffer(
      data: diffPtr.baseAddress,
      height: vImagePixelCount(height),
      width: vImagePixelCount(width),
      rowBytes: width
    )
    
    do {
      var normalizedBuffer = try vImage_Buffer(
        width: width,
        height: height,
        bitsPerPixel: UInt32(imageContextBitsPerComponent)
      )
      defer { normalizedBuffer.free() }
      
      let error = vImageContrastStretch_Planar8(
        &diffBuffer,
        &normalizedBuffer,
        vImage_Flags(kvImageNoFlags)
      )
      
      let buffer = error == kvImageNoError ? normalizedBuffer : diffBuffer
      
      return try buffer.createCGImage(format: outputFormat)
    } catch {
      return nil
    }
  }
  
  guard let outputCgImage else { return nil }
  
  return UIImage(cgImage: outputCgImage, scale: scale, orientation: .up)
}
#endif
