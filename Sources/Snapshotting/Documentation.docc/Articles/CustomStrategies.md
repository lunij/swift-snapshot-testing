# Defining custom snapshot strategies

While Snapshotting comes with a wide variety of snapshot strategies, it can also be extended with
custom, user-defined strategies using the ``Snapshotting/SnapshotStrategy``,
``Snapshotting/SnapshotSerializer``, and ``Snapshotting/SnapshotComparator`` types.

## SnapshotStrategy

The ``Snapshotting/SnapshotStrategy`` type represents the ability to transform a snapshottable value
(like a view or data structure) into a diffable format (like an image or text).

### Transforming existing strategies

Existing strategies can be transformed to work with new types using the `transform` methods.

For example, given the following `image` strategy on `UIView`:

``` swift
SnapshotStrategy<UIView, UIImage>.image
```

We can define an `image` strategy on `UIViewController` from it:

``` swift
extension SnapshotStrategy where Value == UIViewController, Format == UIImage {
  public static let image: SnapshotStrategy = SnapshotStrategy<UIView, UIImage>
    .image
    .transform { $0.view }
}
```

The transform runs in the opposite direction to the strategy: it goes from the new strategy's value
to the existing strategy's value, in this case `(UIViewController) -> UIView`.

The `to:` argument names the new strategy's value type. It defaults to the generic, so it can be left
off wherever the compiler can infer that type from context — such as from the return type of the
property being defined:

``` swift
public static var image: SnapshotStrategy<UIViewController, UIImage> {
  SnapshotStrategy<UIView, UIImage>.image.transform { $0.view }
}
```

### Creating brand new strategies

Most strategies can be built from existing ones, but if you've defined your own
``Snapshotting/SnapshotSerializer`` and ``Snapshotting/SnapshotComparator``, you can create a
base ``Snapshotting/SnapshotStrategy`` value from them directly.

### Identifying what a strategy renders

References are named after the strategy that recorded them, so two strategies for the same value have
to be told apart. ``SnapshotStrategy/pathExtension`` does that on its own whenever the formats differ
— an image against a description, JSON against a property list — and in that case
``SnapshotStrategy/identifier`` stays `nil`.

Set one when it doesn't. A request rendered as a cURL command and the same request rendered raw are
both `txt`, so each says which it is:

``` swift
extension SnapshotStrategy where Value == URLRequest, Format == String {
  public static var curl: SnapshotStrategy {
    DirectSnapshotStrategy.lines.transform(identifier: "curl") { request in /* … */ }
  }
}
```

`transform` carries the identifier over, so a strategy derived from one that already
identifies itself needs nothing further.

### Asynchronous Strategies

Some types need to be snapshot in an asynchronous fashion. ``Snapshotting/SnapshotStrategy``
supports this natively: the `snapshot` closure and the transform passed to
``SnapshotStrategy/transform(to:identifier:_:)-(_,_,)`` are both `async`, so you can `await` anything inside them.

#### Async transforms

For example, WebKit's `WKWebView` offers a callback-based API for taking image snapshots. You can
bridge it to `async/await` using `withCheckedContinuation`:

``` swift
extension SnapshotStrategy where Value == WKWebView, Format == UIImage {
  public static let image: SnapshotStrategy = SnapshotStrategy<UIImage, UIImage>
    .image
    .transform { @MainActor webView async in
      await withCheckedContinuation { continuation in
        webView.takeSnapshot(with: nil) { image, _ in
          continuation.resume(returning: image ?? UIImage())
        }
      }
    }
}
```

Spell the `async` out on a `@MainActor` closure even when the body's `await` already implies it.
Without it the closure is inferred to be `@Sendable`, which a non-`Sendable` value like a view cannot
be passed through.

#### Async initialization

`SnapshotStrategy` accepts an `async` closure directly in its initializer, so you can describe
asynchronous strategies without transforming an existing one:

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
