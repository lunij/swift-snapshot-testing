# Integrating with test frameworks

Learn how to use snapshot testing with Swift Testing, Apple's native testing framework.

## Overview

SnapshotTesting integrates natively with Swift Testing. You can use
``assertSnapshot(of:as:named:record:isolation:fileID:file:testName:line:column:)`` directly in any
`@Test` function:

```swift
@Test
func testFeature() {
  assertSnapshot(of: MyView(), as: .image)
}
```

### Configuring snapshots

Snapshot behavior is controlled by two properties on ``SnapshotTestingConfiguration``:
``SnapshotTestingConfiguration/diffTool-swift.property`` and
``SnapshotTestingConfiguration/record-swift.property``.

The `diffTool` property lets you customize the command printed in test failure messages for opening
a diff between two files, such as [Kaleidoscope](http://kaleidoscope.app). The `record` property
controls when snapshots are generated and saved to disk.

Apply the ``Testing/Trait/snapshots`` trait to a test or suite to override these properties:

```swift
import SnapshotTesting

@Suite(.snapshots(record: .failed, diffTool: .ksdiff))
struct FeatureTests {
  …
}
```

You can also override them for the scope of a single operation using
``withSnapshotTesting(record:diffTool:operation:)-2kuyr``:

```swift
@Test
func testFeature() {
  withSnapshotTesting(record: .all, diffTool: .ksdiff) {
    assertSnapshot(…)
  }
}
```

#### Record modes

The `record` property accepts one of four modes:

- `all`: All snapshots are generated and saved to disk.
- `missing`: Only snapshots that are missing from disk are generated.
- `never`: No snapshots are generated, even if they are missing. Recommended for CI environments to
  prevent retries from unexpectedly passing after snapshots are generated.
- `failed`: Only snapshots for failing tests are generated. Useful with precision thresholds so
  passing tests don't re-record subtly different snapshots that are still within the threshold.

#### Custom diff tools

`diffTool` accepts a [`DiffTool`](<doc:SnapshotTestingConfiguration/DiffTool-swift.struct>) value — a
function `(String, String) -> String` that receives the paths of the reference and failure snapshot
files and returns a shell command. You can define your own:

```swift
extension SnapshotTestingConfiguration.DiffTool {
  static let compare = Self {
    "compare \"\($0)\" \"\($1)\" png: | open -f -a Preview.app"
  }
}
```
