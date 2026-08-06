#if os(iOS) || os(tvOS)
import SceneKit
import SpriteKit
import UIKit

@MainActor
func prepareView(
  profile: DeviceProfile,
  in host: ViewHost = .offscreenWindow,
  traits: @escaping TraitMutations,
  view: UIView,
  viewController: UIViewController
) throws -> () -> Void {
  let size = profile.size ?? viewController.view.frame.size
  view.frame.size = size
  if view != viewController.view {
    viewController.view.bounds = view.bounds
    viewController.view.addSubview(view)
  }
  // Mutations run in order, so the passed-in traits override the profile's,
  // mirroring the merge semantics of the old `UITraitCollection(traitsFrom:)`.
  let profileTraits = profile.traits
  let traits: TraitMutations = { mutableTraits in
    profileTraits(&mutableTraits)
    traits(&mutableTraits)
  }
  let (window, restoreWindow) = try host.window(
    for: viewController,
    profile: profile,
    size: size,
    traits: traits
  )
  let dispose = add(traits: traits, viewController: viewController, to: window)

  if size.width == 0 || size.height == 0 {
    // Try to call sizeToFit() if the view still has invalid size
    view.sizeToFit()
    view.setNeedsLayout()
    view.layoutIfNeeded()
  }

  return {
    dispose()
    restoreWindow()
  }
}

@MainActor
func snapshotView(
  profile: DeviceProfile,
  in host: ViewHost,
  scale: CGFloat,
  traits: @escaping TraitMutations,
  view: UIView,
  viewController: UIViewController
) async throws -> UIImage {
  let initialFrame = view.frame
  let dispose = try prepareView(
    profile: profile,
    in: host,
    traits: traits,
    view: view,
    viewController: viewController
  )
  // Metal-backed views must be captured through their own snapshot API;
  // rendering their layer yields an empty image. WKWebView is excluded:
  // its layer renders fine, and `takeSnapshot` would ignore the
  // strategy's `scale` parameter.
  if view is SCNView || view is SKView, let image = await view.snapshot {
    view.frame = initialFrame
    dispose()
    return image
  }
  let views = await addImagesForRenderedViews(view)
  let image = view.convertToImage(scale: scale, traits: traits, in: host)
  for view in views { view.removeFromSuperview() }
  view.frame = initialFrame
  dispose()
  return image
}

@MainActor
func renderer(bounds: CGRect, scale: CGFloat, traits: @escaping TraitMutations) -> UIGraphicsImageRenderer {
  let format = UIGraphicsImageRendererFormat(for: UITraitCollection(mutations: traits))
  format.scale = scale
  return UIGraphicsImageRenderer(bounds: bounds, format: format)
}

@MainActor
private func add(
  traits: @escaping TraitMutations,
  viewController: UIViewController,
  to window: UIWindow
) -> () -> Void {
  // The window may be the host application's, whose root outlives the snapshot, so `dispose`
  // reinstates it rather than leaving the window empty.
  let originalRootViewController = window.rootViewController
  let rootViewController: UIViewController
  if viewController != window.rootViewController {
    rootViewController = UIViewController()
    rootViewController.view.backgroundColor = .clear
    rootViewController.view.frame = window.frame
    rootViewController.view.translatesAutoresizingMaskIntoConstraints =
      viewController.view.translatesAutoresizingMaskIntoConstraints
    rootViewController.preferredContentSize = rootViewController.view.frame.size
    viewController.view.frame = rootViewController.view.frame
    rootViewController.view.addSubview(viewController.view)
    if viewController.view.translatesAutoresizingMaskIntoConstraints {
      viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    } else {
      NSLayoutConstraint.activate([
        viewController.view.topAnchor.constraint(equalTo: rootViewController.view.topAnchor),
        viewController.view.bottomAnchor.constraint(
          equalTo: rootViewController.view.bottomAnchor
        ),
        viewController.view.leadingAnchor.constraint(
          equalTo: rootViewController.view.leadingAnchor
        ),
        viewController.view.trailingAnchor.constraint(
          equalTo: rootViewController.view.trailingAnchor
        )
      ])
    }
    rootViewController.addChild(viewController)
  } else {
    rootViewController = viewController
  }
  // Overrides propagate to descendants, so applying them on the root also
  // applies them to `viewController`. Saving the previous value lets `dispose`
  // restore the controller untouched when it is the window's own root.
  let originalTraitOverrides = rootViewController.traitOverrides
  var mutableTraits: any UIMutableTraits = rootViewController.traitOverrides
  traits(&mutableTraits)
  rootViewController.traitOverrides = mutableTraits as! UITraitOverrides
  viewController.didMove(toParent: rootViewController)

  window.rootViewController = rootViewController

  rootViewController.beginAppearanceTransition(true, animated: false)
  rootViewController.endAppearanceTransition()

  rootViewController.view.setNeedsLayout()
  rootViewController.view.layoutIfNeeded()

  viewController.view.setNeedsLayout()
  viewController.view.layoutIfNeeded()

  return {
    rootViewController.traitOverrides = originalTraitOverrides
    viewController.beginAppearanceTransition(false, animated: false)
    viewController.willMove(toParent: nil)
    viewController.view.removeFromSuperview()
    viewController.removeFromParent()
    viewController.didMove(toParent: nil)
    viewController.endAppearanceTransition()
    window.rootViewController = originalRootViewController
  }
}
#endif
