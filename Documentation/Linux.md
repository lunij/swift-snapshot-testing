# Linux

Snapshotting builds and tests on Linux. Half the library travels: everything that
compares *values*. Nothing that renders a view does, because there is no UIKit, AppKit
or Core Graphics to render with.

## What works

| Available | Not available |
| --- | --- |
| `.dump`, `.description`, `.json`, `.plist`, `.lines` | `.image` in every form |
| `.curl`, `.raw` for `URLRequest` | `.recursiveDescription`, `.hierarchy` |
| Inline snapshots, including `assertInlineSnapshot` | `DeviceProfile` and trait overrides |
| Record modes, `SnapshotLocation`, the diff output | `CALayer`, SceneKit, SpriteKit, WKWebView |

The visual strategies are compiled out behind `canImport(CoreGraphics)`,
`canImport(UIKit)` and `canImport(SwiftUI)`, so they are absent rather than failing at
runtime. `URLRequest` needs `FoundationNetworking`, which the library imports for you.

CI runs the Linux suite on every push in a `swift:6.3` container. That job is the
definition of what Linux support means here — if it passes, the platform is supported.

## Running the tests on Linux

On a Linux machine, nothing special is required:

```sh
swift test
```

## Running the Linux tests from a Mac

A container is the only way to exercise the Linux build without pushing. The Makefile
target uses [`apple/container`][container], Apple's open-source runtime built on the
Virtualization framework:

```sh
make test-linux
```

### Setting up the runtime

```sh
brew install container
container system start
```

`container system start` prompts once to download a default Linux kernel. To answer it
non-interactively — in a script, or when the prompt cannot be reached — pass the flag:

```sh
container system start --enable-kernel-install
```

The runtime does not start at login unless you ask it to with `brew services start
container`. Without that, start it when you need it and `container system stop` when you
are done. If the service is not running, commands fail with `XPC connection error:
Connection invalid` rather than hanging.

Any Docker-compatible runtime works just as well if you already have one — swap
`container` for `docker` in the target; the flags are identical.

### Why the target sets `--cpus` and `--memory`

```make
container run --rm --cpus 8 --memory 8G --volume "$(PWD):$(PWD)" ...
```

Those two flags are required, not tuning. `container` gives every container its own
lightweight VM with a conservative **4 CPU / 1 GB** default, and 1 GB is not enough to
compile SwiftSyntax. The build dies partway through with:

```
make: *** [test-linux] Error 137
```

`137` is `128 + 9`, a `SIGKILL` from the out-of-memory killer. It first looks like a
hang — output stops for minutes before the kill lands. Docker does not show this,
because it gives containers a slice of one large shared VM instead of a VM each.

Lower the numbers if your machine is smaller, but keep them well above 1 GB.

### Build products are kept separate

The recipe passes `--scratch-path .build/linux` so the container never writes to the
`.build` directory Xcode and `swift build` use on the host. The two toolchains would
otherwise invalidate each other's products through the bind mount, and every switch
between macOS and Linux would trigger a full rebuild.

### What to expect

Starting a container takes about a second. The first run is slower for one-time
reasons — it downloads and unpacks the `swift:6.3` image, roughly 3.7 GB — and a cold
build of the package takes several minutes. Later runs reuse both, and an incremental
test run finishes in well under a minute.

[container]: https://github.com/apple/container
