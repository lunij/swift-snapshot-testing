# Defining custom snapshot strategies

While Snapshotting comes with a wide variety of snapshot strategies, it can also be extended with
custom, user-defined strategies using the ``Snapshotting/SnapshotStrategy``,
``Snapshotting/SnapshotSerializer``, and ``Snapshotting/SnapshotComparator`` types.

## SnapshotStrategy

The ``Snapshotting/SnapshotStrategy`` type represents the ability to transform a snapshottable value
(like a view or data structure) into a diffable format (like an image or text).

### Transforming existing strategies

Existing strategies can be transformed to work with new types using the `pullback` method.

For example, given the following `image` strategy on `UIView`:

``` swift
SnapshotStrategy<UIView, UIImage>.image
```

We can define an `image` strategy on `UIViewController` using the `pullback` method:

``` swift
extension SnapshotStrategy where Value == UIViewController, Format == UIImage {
  public static let image: SnapshotStrategy = SnapshotStrategy<UIView, UIImage>
    .image
    .pullback { viewController in viewController.view }
}
```

Pullback takes a transform function from the new strategy's value to the existing strategy's value,
in this case `(UIViewController) -> UIView`.

### Creating brand new strategies

Most strategies can be built from existing ones, but if you've defined your own
``Snapshotting/SnapshotSerializer`` and ``Snapshotting/SnapshotComparator``, you can create a
base ``Snapshotting/SnapshotStrategy`` value from them directly.

### Asynchronous Strategies

Some types need to be snapshot in an asynchronous fashion. ``Snapshotting/SnapshotStrategy``
supports this natively: the `snapshot` closure and the transform passed to
``SnapshotStrategy/asyncPullback(_:)`` are both `async`, so you can `await` anything inside them.

#### Async pullbacks

Alongside ``SnapshotStrategy/pullback(_:)`` there is ``SnapshotStrategy/asyncPullback(_:)``, which takes an
`async` transform function `(NewStrategyValue) async -> ExistingStrategyValue`.

For example, WebKit's `WKWebView` offers a callback-based API for taking image snapshots. You can
bridge it to `async/await` using `withCheckedContinuation`:

``` swift
extension SnapshotStrategy where Value == WKWebView, Format == UIImage {
  public static let image: SnapshotStrategy = SnapshotStrategy<UIImage, UIImage>
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

`SnapshotStrategy` accepts an `async` closure directly in its initializer, so you can describe
asynchronous strategies without going through `asyncPullback`:

``` swift
extension SnapshotStrategy where Value == WKWebView, Format == UIImage {
  public static let image = SnapshotStrategy(
    pathExtension: "png",
    serializer: .image,
    comparator: .image,
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

## SnapshotSerializer and SnapshotComparator

Two types handle the persistence and comparison concerns of a snapshot format value:

- ``Snapshotting/SnapshotSerializer`` converts a snapshot format value to and from raw `Data` for
  disk storage.
- ``Snapshotting/SnapshotComparator`` compares two snapshot format values and produces a
  ``Snapshotting/SnapshotFailure`` when they differ.

To define custom serialization and comparison for a type, initialize each with the appropriate
closure:

``` swift
extension SnapshotSerializer where Value == MyImage {
  static let myImage = SnapshotSerializer(
    toData: { $0.pngData()! },
    fromData: { MyImage(data: $0)! }
  )
}

extension SnapshotComparator where Value == MyImage {
  static let myImage = SnapshotComparator { old, new in
    guard old != new else { return nil }
    return SnapshotFailure(
      reason: "Images did not match",
      artifacts: [
        .init(name: "reference", data: old.pngData()!),
        .init(name: "failure", data: new.pngData()!),
      ]
    )
  }
}
```

``SnapshotArtifact`` values are handed back on ``SnapshotResult/artifacts``, for the caller to
surface however it reports failures.

The `SnapshotFailure` itself reaches the caller intact, as ``SnapshotResult/Outcome/mismatched(_:)``.
Prefer switching over ``SnapshotResult/outcome`` to matching on ``SnapshotResult/failureMessage``,
which renders the outcome for a human and is free to change its wording.
