#if os(macOS)
import Cocoa

extension XView {
  @MainActor func convertToImage(scale: CGFloat) -> XImage {
    let originalSize = bounds.size

    guard
      let bitmapRep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: SnapshotScale.pixelCount(originalSize.width, at: scale),
        pixelsHigh: SnapshotScale.pixelCount(originalSize.height, at: scale),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
      )
    else {
      return NSImage(size: originalSize)
    }

    // Setting the rep's point size to the unscaled bounds while keeping
    // its pixel dimensions at Nx causes `cacheDisplay` to render at the
    // higher backing resolution. (`cacheDisplay` ignores the current
    // NSGraphicsContext, so applying `scaleBy` to it has no effect.)
    bitmapRep.size = originalSize
    cacheDisplay(in: bounds, to: bitmapRep)

    let image = NSImage(size: originalSize)
    image.addRepresentation(bitmapRep)
    return image
  }
}
#elseif os(iOS) || os(tvOS)
import UIKit

extension XView {
  @MainActor func convertToImage(scale: CGFloat, traits: @escaping TraitMutations, drawHierarchyInKeyWindow: Bool) -> XImage {
    renderer(bounds: bounds, scale: scale, traits: traits).image { ctx in
      if drawHierarchyInKeyWindow {
        drawHierarchy(in: bounds, afterScreenUpdates: true)
      } else {
        layer.render(in: ctx.cgContext)
      }
    }
  }
}
#endif
