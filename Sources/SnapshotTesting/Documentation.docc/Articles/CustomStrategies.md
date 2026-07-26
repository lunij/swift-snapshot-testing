# Defining custom snapshot strategies

While SnapshotTesting comes with a wide variety of snapshot strategies, it can also be extended with
custom, user-defined strategies using the ``SnapshotTesting/Snapshotting`` and
``SnapshotTesting/Diffing`` types.

## Snapshotting

The ``SnapshotTesting/Snapshotting`` type represents the ability to transform a snapshottable value
(like a view or data structure) into a diffable format (like an image or text).

### Transforming existing strategies

Existing strategies can be transformed to work with new types using the `pullback` method.

For example, given the following `image` strategy on `UIView`:

``` swift
Snapshotting<UIView, UIImage>.image
```

We can define an `image` strategy on `UIViewController` using the `pullback` method:

``` swift
extension Snapshotting where Value == UIViewController, Format == UIImage {
  public static let image: Snapshotting = Snapshotting<UIView, UIImage>
    .image
    .pullback { viewController in viewController.view }
}
```

Pullback takes a transform function from the new strategy's value to the existing strategy's value,
in this case `(UIViewController) -> UIView`.

### Creating brand new strategies

Most strategies can be built from existing ones, but if you've defined your own
``SnapshotTesting/Diffing`` strategy, you may need to create a base ``SnapshotTesting/Snapshotting``
value alongside it.

### Asynchronous Strategies

Some types need to be snapshot in an asynchronous fashion. ``SnapshotTesting/Snapshotting``
supports this natively: the `snapshot` closure and the transform passed to
``Snapshotting/asyncPullback(_:)`` are both `async`, so you can `await` anything inside them.

#### Async pullbacks

Alongside ``Snapshotting/pullback(_:)`` there is ``Snapshotting/asyncPullback(_:)``, which takes an
`async` transform function `(NewStrategyValue) async -> ExistingStrategyValue`.

For example, WebKit's `WKWebView` offers a callback-based API for taking image snapshots. You can
bridge it to `async/await` using `withCheckedContinuation`:

``` swift
extension Snapshotting where Value == WKWebView, Format == UIImage {
  public static let image: Snapshotting = Snapshotting<UIImage, UIImage>
    .image
    .asyncPullback { @MainActor webView async -> UIImage in
      await withCheckedContinuation { continuation in
        webView.takeSnapshot(with: nil) { image, _ in
          continuation.resume(returning: image ?? UIImage())
        }
      }
    }
}
```

#### Async initialization

`Snapshotting` accepts an `async` closure directly in its initializer, so you can describe
asynchronous strategies without going through `asyncPullback`:

``` swift
extension Snapshotting where Value == WKWebView, Format == UIImage {
  public static let image = Snapshotting(
    pathExtension: "png",
    diffing: .image,
    snapshot: { @MainActor webView async -> UIImage in
      await withCheckedContinuation { continuation in
        webView.takeSnapshot(with: nil) { image, _ in
          continuation.resume(returning: image ?? UIImage())
        }
      }
    }
  )
}
```

## Diffing

The ``SnapshotTesting/Diffing`` type represents the ability to compare `Value`s and convert them to
and from `Data`.

To define a custom diffing strategy, use the ``Diffing/diff(toData:fromData:diffV2:)`` static method
and return ``DiffAttachment`` values to describe failure artifacts such as reference images, failure
images, and difference images:

``` swift
extension Diffing where Value == MyImage {
  static let myImage = Diffing.diff(
    toData: { $0.pngData()! },
    fromData: { MyImage(data: $0)! }
  ) { old, new in
    guard old != new else { return nil }
    return (
      "Images did not match",
      [
        .data(old.pngData()!, name: "reference.png"),
        .data(new.pngData()!, name: "failure.png"),
      ]
    )
  }
}
```

``DiffAttachment`` values are surfaced as test attachments in Swift Testing results. The
``DiffAttachment/data(_:name:)`` case accepts raw `Data` and a file name and is the preferred
approach for custom strategies.

If you need to access the diff result of an existing ``Diffing`` value directly, use the
``Diffing/diffV2`` property, which returns `[DiffAttachment]`:

``` swift
if let (message, attachments) = diffing.diffV2(expected, actual) {
  // attachments: [DiffAttachment]
}
```
