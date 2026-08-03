# 📸 Snapshotting

[![CI](https://github.com/lunij/swift-snapshotting/actions/workflows/ci.yml/badge.svg)](https://github.com/lunij/swift-snapshotting/actions/workflows/ci.yml)

Snapshot testing for Swift 6, built on Swift Testing and async/await.

## Usage

Once [installed](#installation), _no additional configuration is required_. You can import the
`SnapshotTesting` module and call the `assertSnapshot` function.

``` swift
import SnapshotTesting
import Testing

@MainActor
struct MyViewControllerTests {
  @Test func myViewController() async {
    let vc = MyViewController()

    await assertSnapshot(of: vc, as: .image)
  }
}
```

Assertions are asynchronous, since capturing a snapshot may have to wait for the value to finish
rendering. Every assertion is awaited from an `async` test.

When an assertion first runs, a snapshot is automatically recorded to disk and the test will fail,
printing out the file path of any newly-recorded reference.

> ❌ No reference was found on disk. Automatically recorded snapshot: …
>
> open "…/MyAppTests/\_\_Snapshots\_\_/MyViewControllerTests/myViewController.png"
>
> Re-run to compare against the newly-recorded snapshot.

Repeat test runs will load this reference and compare it with the runtime value. If they don't
match, the test will fail and describe the difference. Failures can be inspected from Xcode's Report
Navigator, where the reference and the mismatching snapshot are attached to the failure, or by
inspecting the file URLs printed in the failure message.

### Naming

A reference is named after the test that took it, plus what the strategy renders when its file
extension doesn't already say — `.image` produces `myViewController.png`, while `.curl` and `.raw`
produce `myRequest.curl.txt` and `myRequest.raw.txt`. Pass `suffixed:` for what nothing else can
supply, such as telling two snapshots of one test apart:

```swift
await assertSnapshot(of: vc, as: .image, suffixed: "logged out")
```

A suffix is one more component of the name rather than a licence to reuse it: two snapshots of one
test that land on the same file are reported rather than allowed to overwrite each other, whether
they got there by repeating a suffix or by omitting one. They may share a reference as long as
neither records to it, which is what lets a test compare one reference against two values in turn.

#### One reference, or one per platform

The same test running on two platforms rarely renders the same thing. So a reference is looked for at
three names, most specific first:

```
myViewController.ios26.png    the platform and its major version
myViewController.ios.png      the platform
myViewController.png          shared by every platform
```

The most specific one that exists is used, and a snapshot with no reference yet records the shared
name. Output that doesn't depend on the platform therefore keeps one reference indefinitely, with
nothing to configure.

To split one apart, rename it after the platform that recorded it and re-run — the other platform
then records its own. A mismatch against a shared reference says as much:

> 'myViewController.png' is shared by every platform. If it differs because of the platform this ran
> on, rename it after the platform that recorded it — this run then records 'myViewController.ios.png'.

The version rung works the same way and is for output that changes between releases of one platform.
Neither is ever created for you: nothing about the platform enters a name until a file says it should.

### Recording

The record mode decides when a reference is written to disk:

| Mode | Behavior |
| --- | --- |
| `.all` | Writes every snapshot, without comparing. |
| `.failed` | Writes a snapshot whenever a comparison fails. The default. |
| `.missing` | Writes only the snapshots that are not yet on disk. |
| `.never` | Writes nothing, and reports a failure if a reference is missing. Appropriate on CI, so that a re-run cannot succeed on references that were generated unexpectedly. |

`.failed` is useful with precision thresholds: a comparison that passes within its threshold does
not re-record a subtly different snapshot, while a real mismatch leaves the new snapshot on disk
ready to be diffed.

The mode can be set per assertion, for a scope, or for a whole suite:

```swift
// Record just this one snapshot
await assertSnapshot(of: vc, as: .image, record: .all)

// Record all snapshots in a scope:
await withSnapshotConfiguration(record: .all) {
  await assertSnapshot(of: vc1, as: .image)
  await assertSnapshot(of: vc2, as: .image)
  await assertSnapshot(of: vc3, as: .image)
}

// Record all snapshots in a Swift Testing suite:
@Suite(.snapshotRecord(.all))
struct FeatureTests {}
```

To set the mode for a whole test run without touching the source, set the `SNAPSHOTTING_RECORD`
environment variable to `all`, `failed`, `missing` or `never`.

### Diff tools

When a comparison fails, the message ends with a command for opening the reference and the
mismatching snapshot side by side. By default it prints the two file URLs;
`.snapshotDiffTool` and `withSnapshotConfiguration(diffTool:)` swap in a real diff tool:

```swift
// Use Kaleidoscope for a whole suite:
@Suite(.snapshotDiffTool(.ksdiff))
struct FeatureTests {}

// Or for a scope, with a tool of your own:
await withSnapshotConfiguration(diffTool: "opendiff") {
  await assertSnapshot(of: vc, as: .image)
}
```

The two traits carry a single value each and combine, so a suite can set a diff tool while a test
inside it overrides only the record mode.

## Snapshot Anything

While most snapshot testing libraries in the Swift community are limited to `UIImage`s of `UIView`s,
SnapshotTesting can work with _any_ format of _any_ value. The value strategies run everywhere Swift
does, including [Linux](Documentation/Linux.md); the image strategies need an Apple platform.

The `assertSnapshot` function accepts a value and any snapshot strategy that value supports. This
means that a view or view controller can be tested against an image representation _and_ against a
textual representation of its properties and subview hierarchy.

``` swift
await assertSnapshot(of: vc, as: .image)
await assertSnapshot(of: vc, as: .recursiveDescription)
```

View testing is highly configurable. You can override trait collections (for specific size classes
and content size categories) and generate device-agnostic snapshots, all from a single simulator.

``` swift
await assertSnapshot(of: vc, as: .image(on: .iPhone(.year2014)))
await assertSnapshot(of: vc, as: .recursiveDescription(on: .iPhone(.year2014)))

await assertSnapshot(of: vc, as: .image(on: .iPhone(.year2014, .landscape)))
await assertSnapshot(of: vc, as: .recursiveDescription(on: .iPhone(.year2014, .landscape)))

await assertSnapshot(of: vc, as: .image(on: .iPhone(.year2024)))
await assertSnapshot(of: vc, as: .recursiveDescription(on: .iPhone(.year2024)))

await assertSnapshot(of: vc, as: .image(on: .iPad(.year2021, .portrait)))
await assertSnapshot(of: vc, as: .recursiveDescription(on: .iPad(.year2021, .portrait)))
```

A device family is keyed on the year its screen geometry first shipped, and only families a
device on the deployment floor still has are named. Each case's documentation lists the models it
covers. Arbitrary geometry stays available through `.image(size:)`. On tvOS a single `.appleTV`
profile describes the 1920 × 1080 point screen every Apple TV lays out on.

> **Warning**
> Snapshots must be compared using the exact same simulator that originally took the reference to
> avoid discrepancies between images.

Better yet, SnapshotTesting isn't limited to views and view controllers! There are a number of
available snapshot strategies to choose from.

For example, you can snapshot test URL requests (_e.g._, those that your API client prepares).

``` swift
await assertSnapshot(of: urlRequest, as: .raw)
// POST http://localhost:8080/account
// Cookie: session={"userId":"1"}
//
// email=blob%40example.com&name=Blob
```

And you can snapshot test `Encodable` values against their JSON _and_ property list representations.

``` swift
await assertSnapshot(of: user, as: .json)
// {
//   "bio" : "Blobbed around the world.",
//   "id" : 1,
//   "name" : "Blobby"
// }

await assertSnapshot(of: user, as: .plist)
// <?xml version="1.0" encoding="UTF-8"?>
// <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
//  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
// <plist version="1.0">
// <dict>
//   <key>bio</key>
//   <string>Blobbed around the world.</string>
//   <key>id</key>
//   <integer>1</integer>
//   <key>name</key>
//   <string>Blobby</string>
// </dict>
// </plist>
```

In fact, _any_ value can be snapshot-tested by default using its
[mirror](https://developer.apple.com/documentation/swift/mirror)!

``` swift
await assertSnapshot(of: user, as: .dump)
// ▿ User
//   - bio: "Blobbed around the world."
//   - id: 1
//   - name: "Blobby"
```

If your data can be represented as an image, text, or data, you can write a snapshot test for it!

## Snapshotting without a test framework

Snapshotting is split into two libraries. `Snapshotting` is the engine: it captures a value with a
strategy, compares it against a reference file, writes artifacts, and returns what happened. It
imports no test framework and reports nothing on its own. `SnapshotTesting` is a thin layer on top
that decides where reference files live, and turns a result into a Swift Testing issue.

Anything that needs to compare a value against a reference outside of a test — a command line tool
that reviews rendered output, say — can use the engine directly:

```swift
import Snapshotting

let result = await compareSnapshot(
  of: view,
  as: .image,
  against: referenceURL,
  artifactDirectory: artifactDirectory
)

switch result.outcome {
case .matched:
  break
case .mismatched(let failure):
  print(failure.reason)
default:
  print(result.failureMessage ?? "")
}
```

`SnapshotResult` carries a structured `outcome` alongside the URLs it read and wrote, so callers can
decide what a mismatch means rather than parsing a message. `failureMessage` renders the same
outcome for a human; treat its wording as free to change and switch over `outcome` instead.

Importing `SnapshotTesting` re-exports `Snapshotting`, so a test target only ever imports the one.

## Documentation

Documentation lives in the package's DocC catalogs and can be generated with the
[Swift-DocC plugin](https://github.com/swiftlang/swift-docc-plugin):

```sh
swift package generate-documentation --target Snapshotting --target SnapshotTesting
```

Guides that describe working on the package itself, rather than its API, live in
[`Documentation/`](Documentation):

- [Linux](Documentation/Linux.md) — which strategies travel, and how to run the Linux tests from a
  Mac.

## Installation

### Xcode

> **Warning**
> By default, Xcode will try to add the SnapshotTesting package to your project's main
> application/framework target. Please ensure that SnapshotTesting is added to a _test_ target
> instead, as documented in the last step, below.

 1. From the **File** menu, navigate through **Swift Packages** and select
    **Add Package Dependency…**.
 2. Enter package repository URL: `https://github.com/lunij/swift-snapshotting`.
 3. Confirm the version and let Xcode resolve the package.
 4. On the final dialog, update SnapshotTesting's **Add to Target** column to a test target that
    will contain snapshot tests (if you have more than one test target, you can later add
    SnapshotTesting to them by manually linking the library in its build phase).

### Swift Package Manager

If you want to use SnapshotTesting in any other project that uses
[SwiftPM](https://swift.org/package-manager/), add the package as a dependency in `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/lunij/swift-snapshotting", from: "1.0.0"),
]
```

Next, add `SnapshotTesting` as a dependency of your test target:

```swift
targets: [
  .target(name: "MyApp"),
  .testTarget(
    name: "MyAppTests",
    dependencies: [
      "MyApp",
      .product(name: "SnapshotTesting", package: "swift-snapshotting"),
    ]
  )
]
```

The package vends four libraries:

| Library | Purpose |
| --- | --- |
| `SnapshotTesting` | `assertSnapshot` and the Swift Testing traits. What a test target wants. Re-exports `Snapshotting`. |
| `Snapshotting` | The snapshot engine on its own, free of any test framework. |
| `InlineSnapshotTesting` | `assertInlineSnapshot`, which writes references into the test source instead of to disk. |
| `SnapshottingCustomDump` | The `.customDump` strategy, backed by [swift-custom-dump](https://github.com/pointfreeco/swift-custom-dump). |

## Features

  - [**Dozens of snapshot strategies**][available-strategies]. Snapshot
    testing isn't just for `UIView`s and `CALayer`s. Write snapshots against _any_ value.
  - [**Write your own snapshot strategies**][defining-strategies].
    If you can convert it to an image, string, data, or your own diffable format, you can snapshot
    test it! Build your own snapshot strategies from scratch or transform existing ones.
  - **No configuration required.** Don't fuss with scheme settings. Snapshots are automatically
    saved alongside your tests.
  - **More hands-off.** A missing reference is recorded on the spot, and by default so is a snapshot
    that fails to match, ready to be diffed.
  - **Built for Swift Testing.** Configure a suite or a single test with the `.snapshotRecord` and
    `.snapshotDiffTool` traits. No base class to inherit from.
  - **Device-agnostic snapshots.** Render views and view controllers for specific devices and trait
    collections from a single simulator.
  - **First-class Xcode support.** The reference and the mismatching snapshot are attached to the
    failure in Xcode's test report. Text differences are rendered in the failure message.
  - **A snapshot engine you can use anywhere.** The `Snapshotting` library imports no test
    framework. Text and data strategies carry no UI dependency at all; image and view strategies
    need UIKit or AppKit.
  - **SceneKit, SpriteKit, and WebKit support.** Most snapshot testing libraries don't support these
    view subclasses.
  - **`Codable` support**. Snapshot encodable data structures into their JSON and property list
    representations.
  - **Custom diff tool integration**. Configure failure messages to print diff commands for
    [Kaleidoscope](https://kaleidoscope.app) or your diff tool of choice.
    ``` swift
    @Suite(.snapshotDiffTool(.ksdiff))
    struct FeatureTests {}
    ```

[available-strategies]: Sources/Snapshotting/Documentation.docc/Extensions/SnapshotStrategy.md
[defining-strategies]: Sources/Snapshotting/Documentation.docc/Articles/CustomStrategies.md

## Acknowledgements

This library derives from [pointfreeco/swift-snapshot-testing][upstream], and would not exist
without it. Thank you to Point-Free for building and sharing it.

It has since diverged: Swift 6 only, `async` assertions, Swift Testing with no XCTest, a snapshot
engine split out from the test wrapper, and renamed types. It is not a drop-in replacement, and it
carries no upstream compatibility. If you need support for Swift 5, XCTest, or synchronous
assertions, use [the original][upstream].

[upstream]: https://github.com/pointfreeco/swift-snapshot-testing

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.
