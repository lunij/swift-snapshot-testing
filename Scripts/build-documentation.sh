#!/bin/bash
#
# Builds one DocC archive covering every product of this package on every Apple
# platform that product supports.
#
# A SwiftPM documentation build compiles for the host alone, so it drops every
# declaration behind `#if os(iOS)` — on macOS that is the whole UIKit half of
# the package. This script instead compiles a symbol graph per platform, hands
# all of them to a single `docc convert` per module, which unifies them, and
# merges the per-module archives into one.

set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

# The products to document. Each one needs a scheme of the same name.
modules=(Snapshotting SnapshotTesting SnapshottingCustomDump InlineSnapshotTesting)

# The platforms to document a product on. Documenting a platform means
# compiling for it, so this lists what each product compiles for:
#
#   - watchOS is absent throughout because SnapshotTesting does not build for
#     it: `Attachment.record` needs an `AttachableAsImage` image type, and
#     watchOS has none.
#   - tvOS is absent from the two products that reach swift-custom-dump,
#     because its Speech conformances do not build against the tvOS SDK.
platforms_for() {
  case "$1" in
    Snapshotting | SnapshotTesting) echo "iOS macOS tvOS" ;;
    SnapshottingCustomDump | InlineSnapshotTesting) echo "iOS macOS" ;;
    *)
      echo "error: no platforms listed for $1." >&2
      exit 1
      ;;
  esac
}

build="$root/.build/documentation"
graphs="$build/symbol-graphs"
archives="$build/archives"
output="$build/swift-snapshot-testing.doccarchive"

if [ "$(uname -s)" != "Darwin" ]; then
  echo "error: the iOS and tvOS symbol graphs need xcodebuild, which only runs on macOS." >&2
  exit 1
fi

cd "$root"

# Documenting a platform means compiling for it, and Xcode ships its platforms
# as separate downloads. Say which ones are missing up front: xcodebuild's own
# answer is to build fine until it reaches the platform, then print every
# destination it does have, which reads like a simulator problem.
xcode=$(xcodebuild -version | head -1)
echo "==> Checking platforms against $xcode"
if ! destinations=$(xcodebuild -showdestinations \
  -workspace . \
  -scheme "${modules[0]}" \
  -clonedSourcePackagesDirPath "$root/.build/SourcePackages" 2>&1); then
  echo "$destinations" >&2
  exit 1
fi
missing=()
for platform in $(for module in "${modules[@]}"; do platforms_for "$module"; done | tr ' ' '\n' | sort -u); do
  # A platform Xcode cannot build for still has a destination, carrying the
  # reason it is ineligible.
  if ! echo "$destinations" | grep "platform:$platform," | grep -qv "error:"; then
    missing+=("$platform")
  fi
done
if [ ${#missing[@]} -gt 0 ]; then
  list=$(printf ', %s' "${missing[@]}")
  echo "error: $xcode cannot build for: ${list:2}" >&2
  echo "       The documentation covers those platforms, so each one has to be" >&2
  echo "       installed from Xcode > Settings > Components, or by running:" >&2
  for platform in "${missing[@]}"; do
    echo "         xcodebuild -downloadPlatform $platform" >&2
  done
  exit 1
fi

# Start from nothing. An incremental build skips the targets it considers up to
# date, which leaves their symbol graphs behind at the version they last had.
rm -rf "$build"

for module in "${modules[@]}"; do
  for platform in $(platforms_for "$module"); do
    echo "==> Compiling $module for $platform"
    mkdir -p "$graphs/$platform"
    xcodebuild build \
      -workspace . \
      -scheme "$module" \
      -destination "generic/platform=$platform" \
      -derivedDataPath "$build/DerivedData/$platform" \
      -clonedSourcePackagesDirPath "$root/.build/SourcePackages" \
      -quiet \
      ONLY_ACTIVE_ARCH=YES \
      OTHER_SWIFT_FLAGS='$(inherited) -emit-symbol-graph -emit-extension-block-symbols -emit-symbol-graph-dir "'"$graphs/$platform"'"'
  done
done

mkdir -p "$archives"

for module in "${modules[@]}"; do
  echo "==> Documenting $module"

  # Every module the build touched wrote its symbol graphs to the same
  # directory, dependencies included. Collect this module's own graphs — its
  # module graph plus one extension graph per module it extends — keeping the
  # platforms apart so that identical file names do not collide.
  staged="$build/staged/$module"
  collected=""
  for platform in $(platforms_for "$module"); do
    mkdir -p "$staged/$platform"
    for graph in "$graphs/$platform/$module.symbols.json" "$graphs/$platform/$module@"*.symbols.json; do
      if [ -e "$graph" ]; then
        cp "$graph" "$staged/$platform/"
        collected="yes"
      fi
    done
  done
  if [ -z "$collected" ]; then
    echo "error: $module produced no symbol graph. Does a scheme of that name exist?" >&2
    exit 1
  fi

  catalog=()
  if [ -d "Sources/$module/Documentation.docc" ]; then
    catalog=("Sources/$module/Documentation.docc")
  fi

  xcrun docc convert ${catalog[@]+"${catalog[@]}"} \
    --fallback-display-name "$module" \
    --fallback-bundle-identifier "swift-snapshot-testing.$module" \
    --additional-symbol-graph-dir "$staged" \
    --output-path "$archives/$module.doccarchive" \
    --emit-lmdb-index \
    --warnings-as-errors
done

echo "==> Merging"
xcrun docc merge "$archives"/*.doccarchive \
  --output-path "$output" \
  --synthesized-landing-page-name "Swift Snapshot Testing"

echo "Documentation archive: $output"
