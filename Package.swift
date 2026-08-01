// swift-tools-version:6.1

import PackageDescription

let package = Package(
  name: "swift-snapshotting",
  platforms: [
    .iOS(.v18),
    .macOS(.v15),
    .tvOS(.v18),
    .watchOS(.v11)
  ],
  products: [
    .library(name: "Snapshotting", targets: ["Snapshotting"]),
    .library(name: "SnapshotTesting", targets: ["SnapshotTesting"]),
    .library(name: "InlineSnapshotTesting", targets: ["InlineSnapshotTesting"]),
    .library(name: "SnapshottingCustomDump", targets: ["SnapshottingCustomDump"])
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.5.0"),
    .package(url: "https://github.com/swiftlang/swift-syntax", "509.0.0"..<"605.0.0"),
    .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.0.0")
  ],
  targets: [
    .target(name: "Snapshotting"),
    .testTarget(
      name: "SnapshottingTests",
      dependencies: [
        "Snapshotting"
      ],
      exclude: [
        "__Fixtures__",
        "__Snapshots__",
        "Strategies/__Snapshots__"
      ]
    ),
    .target(name: "SnapshotTesting", dependencies: ["Snapshotting"]),
    .testTarget(
      name: "SnapshotTestingTests",
      dependencies: [
        "Snapshotting",
        "SnapshotTesting"
      ],
      exclude: [
        "__Snapshots__"
      ]
    ),
    .target(
      name: "InlineSnapshotTesting",
      dependencies: [
        "Snapshotting",
        "SnapshotTesting",
        "SnapshottingCustomDump",
        .product(name: "SwiftParser", package: "swift-syntax"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxBuilder", package: "swift-syntax")
      ]
    ),
    .testTarget(
      name: "InlineSnapshotTestingTests",
      dependencies: [
        "InlineSnapshotTesting"
      ]
    ),
    .target(
      name: "SnapshottingCustomDump",
      dependencies: [
        "Snapshotting",
        .product(name: "CustomDump", package: "swift-custom-dump")
      ]
    )
  ],
  swiftLanguageModes: [.v6]
)
